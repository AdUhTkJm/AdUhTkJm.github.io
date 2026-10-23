#import "common.typ": *

== 实验设置

我们在 Polybench @Polybench 上开展测试。Polybench 是由 C 语言编写的 30 个计算程序的集合，它们具有密集的数值核函数（kernels）、规则的循环结构且体量相对较小，是评估的理想选择。在这些程序中，28 个是 @req-analysis 中所定义的 _affine 程序_（仿射程序），其余两个测试用例包含数据依赖的控制流，即 `nussinov.c` 和 `floyd-warshall.c`。其中涉及的控制流实际上是 `min` 或 `max` 函数。尽管理论上可以通过 CSE（公共子表达式消除，common subexpression elimination）优化将其消除，但这样做需要更复杂的分析，超出了本项目范围。

这些程序具有可配置的数据集大小，下文各节使用了小数据集和大数据集。小尺寸主要用于建立正确性，而大尺寸则用于性能分析。

为了保证开发环境的一致性，我们在 Windows Subsystem for Linux (WSL) 上运行测试，但硬件缓存缺失（cache miss）次数计数在原生 Ubuntu 系统上采集，以确保准确性。所有测试均在配备 16 核 CPU 和 512 KB L1 数据缓存的 AMD Ryzen 9 7945HX 上进行。

我们的实现编译为 LLVM 的 release build，采用默认配置。具体而言，编译选项包含 `-O3`，并禁用了 assertions 与 LTO（链接期优化，link-time optimisation）。

== 正确性 <correctness>

我们将我们的结果与 28 个 Polybench 程序中原始 Falcon @Falcon 实现的结果进行比较，以证明正确性。参考实现直接以 `affine` 方言（dialect）为输入。其测试集已提供这些程序的 MLIR kernel，跳过数组初始化与结果打印。我们相应地修改了输入文件（C 源代码）。

在一个测试用例 `adi.c` 中，传给 Falcon 的 MLIR 输入包含一次 CSE 优化，将两次 load 合并，从而影响了缓存缺失次数计数。为保证输入等价，我们手动将其"去优化"（de-optimise），使其与在 Clang IR 中生成的形式一致。

对于小数据集，缓存行大小 $L = 1$、缓存容量 $C = 64, 128$；对于大数据集，$C = 524288$。我们确认了全部 28 个程序的缓存缺失次数完全一致。这表明在测试所用的仿射程序与缓存参数下具有行为等价性，为我们的实现正确性提供了强有力的经验证据。

当 $L > 1$ 时，我们在一个手工编写的小程序上确认了缺失次数完全一致。然而，即使 Polybench 中体积最小的程序，分析也超过了 600 秒的超时，我们因此无法获得进一步的结果。

== 准确性 <accuracy>

我们将我们的模型在 Polybench 程序上的预测与用 Unix 工具 `perf` 测得的缺失次数进行比较，以此衡量模型的准确性。我们使用大数据集，以确保大多数程序的工作集（working set）无法容纳在相对较大的缓存中；否则就不会有容量缺失（capacity miss），相应的模型部分便无法被评估。

当前我们假设每条缓存行包含一个元素。实际上，在我们的设置下每条缓存行为 64 字节，包含测试程序的 8 个元素。为补偿这种不匹配，我们将传给模型的缓存容量输入设置为原来的 8 倍，即 4 MB。这样缓存能容纳的元素个数相同，但空间局部性（spatial locality）将完全丧失。因此我们预期相对误差较大，但能观察到强相关的缩放趋势。

比较结果如 @miss-cmp 所示，其中 $x$ 轴为我们的静态分析预测值，$y$ 轴为硬件实测值，点线表示 $y = x$。左图为对数刻度，右图为线性刻度。

#include "../diagrams/miss-cmp.typ"

绝对次数几乎完全无相关性，但缩放趋势在很大程度上被我们的模型所捕获。

值得注意的是，线性情况下缺乏相关性部分是由于大离群值（`gemm.c`、`jacobi-2d.c`）主导了误差，因此更有意义的是查看每个单独测试用例的相对预测误差。

=== 相对误差分析

@relerror-cdf 绘制了我们测试用例相对误差的累积分布函数（CDF）。

预测结果的相对误差几何平均为 $62.37%$，中位数为 $78.08%$，表明在 $L = 1$ 的假设下，我们的模型只给出了高度近似的缺失次数。

最大误差在 `gemm.c`（矩阵乘法的朴素实现）上达 $673.8%$。其工作集大小恰好约为 4 MB，与我们输入的缓存容量相当。对于这种极端情况，模型的任何差异——例如忽略空间局部性——都会对缓存行为造成巨大影响。

#include "../diagrams/relerror-cdf.typ"

== 性能 <performance>

我们将我们的模型运行时间分别与参考实现 Falcon 以及程序本身的执行时间进行比较，并评估 @optimisations 中描述的优化所带来的改善。

=== 运行时间比较

我们模型与 Falcon 的运行时间对比，以及 Polybench 程序在大数据集下的执行时间，如 @time-cmp 所示。我们的模型与 Falcon 均以 32 线程运行，这是 `nproc` 的结果，即使用整颗 CPU 的全部能力。

平均而言，我们的实现比实际执行快 1.21 倍，表明其效率足以分析实际程序。

模型比 Falcon 慢 22.1 倍（几何平均）。我们以效率换取了 MLIR 集成：我们将 Falcon 中高度优化的 _isl_ 和 _barvinok_ 库替换为 FPL 和一个自研的 Barvinok 算法实现。因此我们预期算法层与低层级的优化更少，从而出现这样的减速。

#include "../diagrams/time-cmp.typ"

这一减速也提示了未来优化的空间，我们在热点分析中（@hotspot）详细探讨。

=== 热点分析 <hotspot>

本节给出的热点分析反映了当前实现的性能。在此之前，我们已多次进行类似分析，并解决了多个瓶颈。相关细节见 @optimisations，这些优化的效果在 @opt-eval 中介绍。

如 @cache-model 所示，我们的算法分为四个部分：计算 $deps(S(bf(x)))$、统计必要缺失（compulsory miss）数量、计算 $dist(S(bf(x)))$、统计容量缺失数量。@time-breakdown 给出了单线程设置下各部分消耗时间的占比。

#include "../diagrams/time-breakdown.typ"

我们注意到容量缺失的最终计数步骤占运行时间的 40%–100%，该步骤对多面体（polyhedra）的并集调用参数化 Barvinok 算法。我们进一步考察该算法的性能。

#include "../diagrams/barvinok-time-breakdown.typ"

如 @incl-excl 所述，该算法由三部分组成：容斥（inclusion-exclusion）、室分解（chamber decomposition）和求和（summation）。我们在 @barvinok-time-breakdown 中按不同析取分量（disjunct）数量绘制了各步骤所占时间百分比。我们发现，无论析取分量个数多少，容斥步骤总是最耗时的。

热点分析表明，我们的模型未来的优化努力应聚焦于 Barvinok 算法，尤其是占运行时间主导地位的容斥部分。这并不意外，因为在最坏情况下，其生成结果（records）的数量可随析取分量个数呈指数增长。然而在我们的静态分析中并未遇到如此病态的情形：如 @barvinok-region 所示，record 数量大约随析取分量个数呈二次增长，表明我们的当前模型能够处理真实世界的程序。该曲线通过 `np.polyfit` 拟合。

#include "../diagrams/barvinok-region.typ"

一个优化机会是减少传入最终计数步骤的析取分量数量——即在 $S(bf(x))$ 与其依赖 $T(bf(y))$ 之间构建复用实例（reuse instance）时，根据易于计算的判据剪除特定语句。由于是二次缩放，该优化将带来可观收益。

== 优化效果 <opt-eval>

=== 缓存室归属 <eval-barvinok-cache>

#include "../diagrams/barvinok-cache-opt.typ"

按 @cache-ownership 所述缓存室归属（chamber ownership），我们将最终求和步骤加速了 5.32 倍，Barvinok 步骤整体加速了 23%（几何平均）。@barvinok-cache-opt 比较了优化前后求和步骤所用时间。

=== 早期消除空关系 <eval-early-removal>

在并合两个分段仿射函数（piecewise affine function）时去除不可行区域，我们缓解了 piece 数量的指数增长，降低了指数的底数。

未优化算法的完整 piece 数量难以获取，因为即使并合 8 个函数，程序也会超时超过 600 秒。经验上，并合 6 个函数后 piece 数量增长到约 16,000。

优化后，如 @piece-count 所示，在 Polybench 上指数增长的底数降至 1.22。具体而言，6 个析取分量时，平均 piece 数量从 16,000 降至 31.5。该优化使我们的分析能够处理 Polybench 中更复杂的 stencil，那里析取分量数量轻松超过 10 个，而待并合的函数数量等于析取分量数量（见 @early-removal）。

#include "../diagrams/piece-count.typ"

=== 并行化 <eval-parallel>

#include "../diagrams/time-cmp-parallel.typ"

我们利用了任务并行：每个语句的缓存缺失次数计算相互独立。这使我们的测试用例获得 3.9 倍加速（几何平均），如 @time-cmp-parallel 所示。

由于测试用例以 32 线程运行，如果加速比不足 4 倍就令人意外。原因在于没有 Polybench 程序的数组访问语句超过 32 个，因此程序运行时间由耗时最长的语句决定。对某语句 $S$，$dist(S(bf(x)))$ 的析取分量数量是决定运行时间的主要指标，如 @hotspot 所示，且在不同语句间可能差异巨大。在 stencil 中，单个语句主导运行时间，加速比低；在线性代数核函数中，各语句的析取分量数量相近，因而加速比更大。

== 总结

贯穿本章，我们看到我们的分析能够捕获缓存缺失次数的渐近行为，而且平均而言比在硬件上运行测试程序收集缺失次数更快。我们对分析当前的热点进行了分析，以指导未来优化。我们评估了若干项优化，并展示了该分析扩展到真实世界规模程序的潜力。
