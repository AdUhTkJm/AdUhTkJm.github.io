#import "common.typ": *
#set math.mat(delim: "[")

== 工作流程概述

我们的分析基于 Clang IR 项目——它既是 C 前端，也是一个 MLIR 方言。其工作流程总结在 @workflow 中。

#include "../diagrams/workflow.typ"

我们从 Clang IR 出发，将其部分提升为 Affine IR。该步骤识别归纳变量及其迭代域，为后续分析做准备。

在提升后的 IR 中，我们将导致缓存缺失的数组下标建模为多面体中的整数点。这通过分析循环内部的数组访问运算实现：计算下标的符号表示，并构造 Presburger 关系。

最终，我们对多面体应用 Barvinok 算法计数其中的整数点，从而得到估计的缓存缺失次数。

== 仓库概述

@repo-overview 概述了我们对 Clang IR 仓库的修改。为简洁起见，图中省略了开发用 shell 脚本和小于十行的微小改动。新引入的仓库文件在图中以蓝色高亮。

我们的修改与上一节描述的三阶段工作流相绑定。代码结构按阶段清晰分离，各阶段位于独立的源文件中。

#include "../diagrams/repo-overview.typ"

在文件 `RaiseToAffine.cpp` 中，我们将 Clang IR 提升为 Affine IR，如 @ir-raising 所述。它识别 C 语言中常见的 for 循环模式，并翻译为仿射循环。同时生成胶水 IR，以将两种不同方言集成到同一 MLIR 模块中。

`RevertLICM.cpp`、`FindOffset.cpp` 和 `ComputeDeps.cpp` 中的 pass 按此顺序执行，以将数组下标间的关系建模为整数多面体。`RevertLICM.cpp` 重构 IR 以简化 `FindOffset.cpp` 的执行，后者用分析所得的下标注释相关运算。最后一个 pass `ComputeDeps.cpp` 将数组下标上的关系翻译为多面体。

计数步骤实现于 `Barvinok.cpp`，它消费建模步骤中的多面体，并给出缓存缺失次数估计。我们基于 MLIR 中现有的未完成工作，在该文件中完成了 Barvinok 算法。

除这些核心组件外，还修改了 Clang IR 仓库中已有的文件，以便将我们的 pass 整合进 MLIR 框架并收集性能数据。

总体而言，我们的仓库体现了需求分析 (@req-analysis) 中识别的模块化分解，并在此基础上扩展以应对项目复杂度。

== 预处理 pass <preprocess>

=== IR 提升 <ir-raising>

在这一阶段，我们将 Clang IR 中的仿射循环提升为 MLIR 的 `affine` 方言，使后续 pass 能够分析循环结构及其归纳变量。

我们关注如下经典 C 循环结构。

```c
for (i = a; i < n; i++)
```

在 Clang IR 中，每个全局变量都被赋予一个栈地址（一个 ```mlir cir.alloca``` 运算）。循环被生成为 ```mlir cir.for``` 运算。该循环有三个 region，分别为：`cond` 对应循环条件 `i < n`，`body` 对应循环体，`step` 对应增量 `i++`。初始化语句 `i = a` 被放置在 ```mlir cir.for``` 运算之前，因为它仅在进入循环前执行一次。

为了提升仿射循环，我们匹配 @cir-for-op 所示的模式，提取下界 ```mlir %a```、上界 ```mlir %n``` 和归纳变量```mlir %i```。随后创建具有相同界与相同 body region 的 ```mlir affine.for``` 运算。

#include "../diagrams/cir-for-op.typ"

一个挑战是 Clang IR 循环变量 ``` %i``` 与 `affine` 方言循环变量 ``` %arg``` 之间的类型不匹配。Clang IR 拥有自己的类型 ```mlir !cir.int<s, 32>```（带符号 32 位整数），而 `affine` 方言要求使用 MLIR 内置类型 `index` 作为循环变量。因此我们不能直接将 ``` %i``` 的用途替换为 ``` %arg```。

为此，我们向 Clang IR 扩展了一个类型转换运算 ```mlir cir.from_index```，用于将 `index` 类型转换为所需的 Clang IR 整数类型，使两种 IR 能够互操作。类似地，我们引入了 ```mlir cir.index_cast``` 运算，将 Clang IR 类型转换为 `index`。

我们还处理如下形式的反向循环

```c for (i = a; i >= n; i--)```

将其规范化为等价的递增形式

```c for (j = n; j < a + 1; j++) ```

并将循环内 `i` 的全部用途替换为 `n + a - j - 1`。

规范化对于 @comp-miss-count 中引入的建模阶段的字典序比较的正确性至关重要。

=== 发现偏移与基地址

对数组 `b[i][j]` 的访问可分解为一个 _base_（基）`b` 和一个 _offset_（偏移）$(i, j)$。缓存模型需要我们找到二者：基用于区分不同数组，相当于一次基本的别名分析；偏移用于计算依赖关系。数组访问语句的偏移与基在 `FindOffset.cpp` 中的预处理 pass 中被识别。

访问 `b[i][j]` 在 Clang IR 中如下表示，其中多维访问被降为一系列 ```mlir cir.get_element``` 运算 #footnote[Strictly speaking, Clang IR can generate ```mlir cir.ptr_stride``` operation as well. The operation is similar to `get_element`, and the process of finding offsets and bases is largely unchanged.], 每个作用于单一维度。

```mlir
%1 = cir.get_element %b[%i]
%2 = cir.get_element %1[%j]
%result = cir.load %2
```

我们检查 `load` 运算操作数（类似地，`store` 的地址操作数）的定义运算，期望得到一个 `get_element %addr[%x]`。我们检查包围该运算的循环嵌套深度 $d$，并构造仿射表达式

$
  c + sum a_i x_i
$

其中 $c$ 和 $a_i$ 初始设为零。

系数通过递归沿 `%x` 的 use-def 链向上遍历，沿途处理算术运算获得：

- 对于携带常数 $v$ 的 ```mlir cir.int```，我们将 $c$ 增加 $v$；

- 对于对应 $x_i$ 的值 ```mlir %i```，我们将 $a_i$ 增加 1；

- 对于加减运算 ```mlir cir.binop add```（或 `sub`），我们将两个操作数的仿射表达式相加；

- 对于乘常数 $m$ 的乘法 ```mlir cir.binop mul```，我们将所有系数与常数乘以 $m$。

其他所有表达式都会失败，并被我们的分析 pass 拒绝，因为它们已不再仿射。

为找到基，`%addr` 也递归处理。如果 `%addr` 本身由一个 `get_element` 运算定义，我们就递归检查其地址，即沿地址链向上遍历，直到它是 `alloca` 或全局数组为止。

我们在 @offset-example 中给出一个示例以演示该过程。它是从 Polybench 的 `ludcmp.c` 获取的 Clang IR 适配片段。

#include "../diagrams/offset-example.typ"

我们的分析确定 `%70` 以偏移 $(119 - i, j)$ 访问数组 `A`。基 `A` 通过查看地址操作数 `%69` 以及 `%A`（紫色部分）获得。由于 `get_element` 位于两个嵌套循环内，我们知道偏移是两个归纳变量的仿射函数。第二维的偏移由检查 `%68` 计算得到——它是一个直接引用 $j$ 的 `from_index` 运算（蓝色部分）。第一维的偏移类似获得，在到达 $i$ 之前额外经过一个 `sub` 表达式（绿色部分）。

该 pass 不处理经由任意指针的访问，因为那将需要别名分析，显著增加实现复杂度。

在 pass 之前，我们进行常量折叠与内联，以简化 IR 并减少对复杂跨过程程分析的需求。

每个访问的基与偏移以附加在每次 `get_element` 运算上的属性形式表示。

对于基，我们为每个 `alloca` 或全局数组分配一个整数作为标识，并将 `array_base` 属性附加到 `get_element` 运算上。该属性是首次引入 Clang IR 的。我们不能直接在属性中存储运算或 SSA 值，因为它们在 MLIR 中不可序列化，会被拒绝。

类似地，我们为数组偏移添加了 `array_offset` 属性。该属性存储仿射映射（affine map），MLIR 原生支持。

作为例子，pass 之后的 `get_element` 运算可能形如：

```mlir
%17 = cir.get_element %5[%8] {
  #array_base = 1,
  #array_offset = (d0, d1) -> (d0)
}
```

二维 induction vector `(d0, d1)` 表示该运算嵌套于两个循环中，并以外层循环的归纳变量索引编号为 $1$ 的数组。

=== 恢复 `get_element` 运算的局部性

如上一节所示，数组访问信息关联在 `get_element` 运算上，偏移仿射映射的维度由该运算所在的循环嵌套决定。

我们的分析期望 `get_element` 运算位于访问语句所在的同一循环嵌套中，以便引用外围循环的全部归纳变量。但并非总是如此。考虑 @revert-licm-example, (a) 所示的 IR 结构：

#include "../diagrams/revert-licm-example.typ"

load 嵌套于两个循环中，其 induction vector 为 $(i, j)$，但其 `get_element` 仅嵌套于一个循环中，在我们的分析中认为其 induction vector 为 $j$。维数不匹配违背了我们的假设。

在代码生成中，这种结构通常不会出现。`get_element` 运算紧邻于 load 或 store 之前，如 @revert-licm-example, (b) 所示。该结构产生于内层 `get_element` 运算因循环不变量提取 (LICM) 被提升到循环之外。随后，公共子表达式消除 (CSE) 可能合并这样两个运算，使其与其使用场景进一步分离。

因此，解决该问题的最直接方案是在 Clang IR 中禁用 LICM 与 CSE。考虑到未来与 MLIR 的集成，我们还实现了 `RevertLICM` pass，通过克隆 `get_element` 运算使过程还原，确保每个 load 都直接由一个 `get_element` 前置。

== 缓存缺失计数分析 <cache-model>

=== 计算必要缺失 <comp-miss-count>

为计算必要缺失，我们识别其访问地址此前从未被访问过的语句实例集合。

我们首先识别所有数组访问语句的集合，记为 $cal(L)$。当 $S$ 是一个 ```mlir cir.load``` 或 ```mlir cir.store``` 运算，且其地址操作数为带有基与偏移属性的 ```mlir cir.get_element``` 时，称其访问数组。

随后，我们按照语句在程序中出现顺序，给 $cal(L)$ 中每个语句分配一个正整数，称为 _lexical index_（字典序索引），以便利后续步骤的字典序比较。越早出现的语句获得较小的索引。$S in cal(L)$ 的字典序索引记为 $i_S$。

我们逐个考虑 $S in cal(L)$ 中的每个语句。在 @dep-compute 中，我们定义了 $S(bf(x))$ 与另一访问运算 $T(bf(y))$ 之间的依赖概念。我们枚举所有 $T in cal(L)$，并构造依赖关系：

$
  "depend"(S, T) = {(bf(x), bf(y)) | S(bf(x)) "depends on" T(bf(y))}
$

如 @dep-compute 所述，在我们的缓存模型中，$S$ 依赖 $T$，当二者访问同一地址且 $T$ 在 $S$ 之前执行时。

在 @fpl 中，我们指出 FPL 仅支持仿射约束。现在我们说明依赖条件确实可以用仿射约束表达。

边界条件以及 $S[bf(x)] = T[bf(y)]$ 的条件是仿射的，因为所有循环界与数组访问都被假设为仿射。

为确保 $S(bf(x))$ 在 $T(bf(y))$ 之后执行，只需要求 $S(bf(x)) lexge T(bf(y))$，因为所有循环均已如 @ir-raising 所述规范化为递增循环。设 $S$ 与 $T$ 的共同循环深度为 $d$。当 $S$ 和 $T$ 位于同一循环嵌套中，我们按定义构造字典序比较：

$
  S(bf(x)) lexge T(bf(y)) <==> or.big_(j=0)^(d-1) (bf(x)_j > bf(y)_j and and.big_(i=0)^(j-1) (bf(x)_i = bf(y)_i))
$

当并非如此时，我们在穷尽所有公共循环后退回字典序。仅当 $T$ 字典序在 $S$ 之前时，我们将上述关系与以下析取式取并：

$
  and.big_(i=0)^(d-1) bf(x)_i = bf(y)_i
$

我们需要找到 $deps(S(bf(x)))$——在所有考察过的 $T$ 中，$S(bf(x))$ 最新、即字典序最大的依赖。由于它们可能位于不同深度、不同嵌套的循环中，它们的归纳变量无法直接比较。我们已说明如何比较两个实例 $S(bf(x))$ 与 $T(bf(y))$ 的执行顺序，但要更一般地比较候选，我们必须将向量嵌入一个公共空间，以同时编码字典序与循环结构。

设 $n$ 为所有候选语句 $T$ 中最大嵌套循环深度，并定义一个循环的字典序索引为其内部语句最小字典序索引。假设 $T(bf(y))$ 的字典序索引为 $i_T$，且嵌套于索引为 $i_0, dots, i_m$ 的循环中。我们将 $bf(y) = (y_0, dots, y_m)$ 提升为

$
  bf(z) = (i_0, y_0, i_1, y_1, dots, i_m, y_m, underbrace(#[$i_T, 0, dots, i_T, 0$], n - m "pairs"), i_T)
$

在嵌入中，每一对 $i_m, y_m$ 同时编码了循环身份与对应归纳变量的取值。填充项 $i_T, 0$ 表示没有循环，用于维持不同深度语句之间的正确字典序。最后的 $i_T$ 作为同一循环嵌套内语句的排序标准。

乍看之下，似乎将 $bf(y)$ 提升为以下形式即可：

$
  bf(z) = (i_0, y_0, i_1, y_1, dots, i_m, y_m, 0, 0, dots, 0, 0, i_T)
$

然而这一变体对非完全嵌套的循环不成立，因为它缺少循环层级之外语句的字典序信息。考虑如下示例：
```python
for i:
  for j:
    load a[i]     # T1: index = 1
  load a[j]       # T2: index = 2
```

在此情形下，若在 $y_m$ 之后填充零，我们将得到

$
  bf(x)_(T_1) = (1, i, 1, j, 1) \
  bf(x)_(T_2) = (1, i, 0, 0, 2) \
$

当 $i$ 取相同值时，$T_1$ 应字典序位于 $T_2$ 之前，但提升后的向量却暗示相反。

将全部依赖候选 $T(bf(y))$ 提升进公共空间后，我们使用 FPL 计算字典序最大值以获得 $deps(S(bf(x)))$。最大化过程在 $bf(x)$ 的定义域上是分段的，因此 FPL 返回一组 _pieces_，即二元组 $(D, bf(z)(bf(x)))$，其中 $bf(z)(bf(x))$ 是作为 $bf(x)$ 函数表达的提升后最大值，$D$ 是 $bf(z)(bf(x))$ 有效的 $bf(x)$ 取值范围。由于 $i_T$ 唯一，提升过程可逆，我们可将任意 $bf(z)(bf(x))$ 降回 $T(bf(y)(bf(x)))$。

程序返回的每个 $D$ 都对应一个存在依赖的区域。将 $S$ 的迭代域减去所有这样的 $D$，得到地址此前未被访问过的区域 $U$。因此 $U$ 的整数点个数即等于必要缺失数量，可用 Barvinok 算法计算。

=== 计算复用距离

复用距离 $dist(S(bf(x)))$ 是严格位于 $deps(S(bf(x)))$ 与 $S(bf(x))$ 之间被访问的不同缓存行数量。由于 $deps(S(bf(x)))$ 在 $bf(x)$ 的迭代域上分段定义，我们必须枚举上一节中计算出的全部 piece $(D, bf(z)(bf(x)))$ 以及降回的语句 $T(bf(y))$。

第一步，我们收集可能在 $S(bf(x))$ 与 $T(bf(y))$ 之间执行的语句，即所有被包含在同时容纳 $S$ 与 $T$ 的最小公共 region 内的数组访问语句。这些语句不仅限于字典序索引介于 $i_S$ 与 $i_T$ 之间的语句，因为位于 $S$ 之后但仍在 $S$ 同区域内执行的语句也可能在 $S(bf(x))$ 与 $T(bf(y))$ 之间执行。对 $T$ 也有类似观察。

每个收集的语句 $U$ 关联一个 induction vector $bf(w)$。我们寻找使 $U$ 在 $T(bf(y))$ 之后、$S(bf(x))$ 之前执行的 $bf(w)$ 取值范围。这些点称为 _reuse instances_（复用实例）。每个这样的 $bf(w)$ 对应 $U$ 的一个在 $S(bf(x))$ 与 $T(bf(y))$ 之间访问内存的实例，当其映射到不同缓存行时，即对复用距离做出贡献。

形式上，

$
  "reuseInstance"(U, S(bf(x)), T(bf(y))) = { bf(w) | bf(y)(bf(x)) lexle bf(w) lexle bf(x) and bf(w) in cal(D)_bf(w) }
$

这里 $cal(D)_bf(w)$ 是 $bf(w)$ 的迭代域，$lexle$ 表示字典序优先，定义见上一节。

为计算 $U$ 访问的内存位置集合，我们将关系 $"reuseInstance"(U, S(bf(x)), T(bf(y)))$ 与 $U$ 的访问函数（一个仿射映射）相复合。然后跨所有 $U$ 取并，得到 $S(bf(x))$ 与 $T(bf(y))$ 之间访问的全部内存位置集合，记为 $"total"(S(bf(x)), T(bf(y)))$。

若假设缓存行大小 $L$ 为 1，则有

$
  dist(S(bf(x))) = \#"total"(S(bf(x)), T(bf(y)))
$

由于 $"total"$ 关系由仿射等式与不等式构成，可视为多面体的 H 表示。因此我们可用 Barvinok 算法计数其中的整数点。

该多面体对 $bf(x)$ 是参数化的。此时 Barvinok 算法给出的计数不是单一整数，而是关于 $bf(x)$ 的 _quasi-polynomial_（准多项式），其形式为

$
  sum_(i=0)^n c_i product_(j=0)^m floor(bf(k)_(i j) dot bf(x) + b_(i j))
$

其中 $c_i$、$bf(k)_(i j)$ 与 $b_(i j)$ 为算法计算的有理数。该形式对下一节引入的容量缺失计数至关重要。

=== 计算容量缺失 <cap-miss-count>

为获得容量 $C$ 的缓存的容量缺失计数，我们逐个考虑 $S in cal(L)$，并统计满足 $dist(S(bf(x))) >= C$ 的 induction vector $bf(x)$ 数量。

当准多项式 $dist(S(bf(x)))$ 的每个乘积至多含一项时，条件 $dist(S(bf(x))) >= C$ 可转化为一个多面体，从而可用 Barvinok 算法高效求解。但更一般的情形下，甚至判定是否存在这样的 $bf(x)$ 就是 NP-hard @ComputationalComplexity。因此我们必须枚举 $bf(x) = (x_1, dots, x_n)$ 以获得精确计数。

我们按维度逐一枚举。给定 $x_1, dots, x_i$ 的固定值，可借助 Simplex 算法确定 $x_(i+1)$ 的取值范围 $[l, r]$。然后遍历其中每个值 $k in [l, r]$，令 $x_(i+1)$ 为 $k$，并递归枚举 $x_(i+2)$。

我们随时在 PWMA 函数被简化为每个乘积至多一项时停止递归过程，此时调用 Barvinok 算法。出于性能考虑，若剩余变量的可能取值不超过 10 个，则继续枚举而非调用更为复杂的 Barvinok 过程。

=== 支持可配置的缓存行大小 <cacheline-size>

前述讨论中我们假设每个数组元素占用一整条缓存行。现在我们说明如何支持缓存行大小 $L > 1$。

我们以二维数组 `a[N][M]` 为例。数组访问 `a[i][j]` 等价于访问地址 `&a + i * M + j`，其映射到缓存行 $floor((i M + j) / L)$。特别地，当假设 $M$ 是 $L$ 的倍数时，我们只需将最后一维 $j$ 替换为 $floor(j / L)$。

然而我们对 $L > 1$ 的支持是有限的。引入取整除法会引入 local 变量，导致生成函数变长，且枚举变得不可避免。即使对小型程序、$L = 3$，我们的实现也无法在 600 秒内终止。

== Barvinok 算法 <barvinok-impl>

我们已在 @barvinok-overview 中给出了 Barvinok 算法的概述。本节说明我们实现的细节。

=== 非参数化投影

我们从一个非参数化的 $d$ 维多面体（既有不等式又有等式）开始：

$ P = { bf(x) in bb(Z)^d | A bf(x) = bf(c), D bf(x) <= bf(f) } $

由于 Barvinok 算法作用于满维多面体，因此需要进行 _projection_（投影），以找到一个新的 $d'$ 维多面体 $Q$，使其整数点数量与 $P$ 相同，且 $Q$ 填满整个 $bb(Z)^(d')$。这意味着 $Q$ 不能含任何等式。

$ Q = { bf(y) in bb(Z)^d' | D' bf(y) <= bf(f)' } $

但其逆命题不成立：即便 $Q$ 不含等式，也不意味着 $Q$ 是满维的。例如，考虑 $bb(Z)^2$ 中的如下多面体：

$
  x - y &>= 0 \
  -x + y &>= 0
$

这显然表明了一个等式 $x = y$，故其位于 $bb(Z)^2$ 的一个 1 维子空间内。

我们通过预处理 $P$ 来防止这种情况。对每个不等式 $D_(i,:) dot bf(x) <= bf(f)_i$，我们在约束 $A bf(x) = bf(c)$ 与 $D bf(x) <= bf(f)$ 下计算 $D_(i, :) dot bf(x)$ 的最小值。这由 FPL 提供的 Simplex 算法完成。当最小值等于 $bf(f)_i$ 时，我们知道该不等式实为等式。

随后我们设法消除所有等式 $A bf(x) = bf(c)$。考虑 $A$ 的 _null space_（零子空间），其定义为

$ null(A) = { bf(x) | A bf(x) = 0 } $

它是一个向量空间。我们寻找一个整数基，使其张成向量空间 $null(A) inter ZZ^m$：$bf(v)_1, bf(v)_2, ..., bf(v)_n$。它们构成一个矩阵：

$ V = mat(bf(v)_1, dots, bf(v)_n) $

于是，方程组 $A bf(x) = bf(c)$ 的任意解 $bf(x)$ 都可表示为

$ bf(x) = V bf(y) + bf(x)_0 $

其中 $bf(x)_0$ 为一个 _particular solution_（特解），即满足方程组的任意整数解。

$bf(x)$ 与 $bf(y)$ 之间存在双射。此外，当 $bf(y)$ 是整数向量时，$bf(x)$ 亦然。其逆也成立：我们有 $bf(y) = V^(-1) (bf(x) - bf(x)_0)$。由于 $V$ 素模而 $V^(-1)$ 因此为整数矩阵，只要 $bf(x)$ 是整数向量，$bf(y)$ 就是整数向量。由于该双射保持整数性，我们可计数向量 $bf(y)$ 而非向量 $bf(x)$，计数结果不变。

若我们将多面体 $P$ 内整数点个数记为 $\#P$，则有

$ \#P
&= \#{ bf(x) in bb(Z)^d | A bf(x) = bf(c), D bf(x) <= bf(f) } \
&= \#{ bf(y) in bb(Z)^(d') | D (V bf(y) + bf(x)_0) <= bf(f) } \
&= \#{ bf(y) in bb(Z)^(d') | underbrace((D V), D') bf(y) <= underbrace(bf(f) - D bf(x)_0, bf(f)') } \
&eq.delta \#Q
$

由此，我们获得投影得到的合适 $Q$，其中 $D' = D V$，$bf(f)' = bf(f) - D x_0$。下面说明如何寻找 $null(A)$ 的基与特解 $bf(x)_0$。

=== 零子空间的整数基

寻找实值矩阵 $M in bb(R)^(n times m)$ 零子空间基时，我们通常将 $M$ 化为 _row-echelon form_（行阶梯形）。对整数矩阵 $A in bb(Z)^(n times m)$，我们需要一个保持整数性的类似概念。这导出了 _Hermite normal form_（赫米特规范形）与 _unimodular matrices_（素模矩阵）。

当整数矩阵的行列式为 $plus.minus 1$ 时称其为 _unimodular_。素模矩阵的逆也是整数矩阵。这是因为

$ M^(-1) = ("adj"(M)) / det(M) $

其中 $"adj"(M)$ 是 $M$ 的伴随矩阵（adjugate）。按定义它各元素均为整数：每个元素是 $M$ 的子矩阵行列式。因此 $M^(-1)$ 各元素亦为整数。@unimod-mat-example 给出了一个素模矩阵及其逆的实例。

#include "../diagrams/unimod-mat-example.typ"

整数矩阵 $A$ 的 _Hermite normal form_ 是满足如下性质的矩阵 $H$：

- 存在一个素模矩阵 $U$，使得 $H = U A$；

- 每行中第一个非零元素，称为 _pivot_（主元），若存在则为正；

- $H$ 为上三角形，即主元下方的元素为零；

- 主元上方的元素为非负且严格小于主元。

@hnf-example 给出了 Hermite normal form 的实例。

FPL 提供计算整数矩阵 $M$ Hermite normal form 的过程。它同时返回 $H$ 与 $U$。

#include "../diagrams/hnf-example.typ"

对 $n times m$ 矩阵 $A$，当 $m <= n$ 且 $A$ 列满秩时，零子空间仅含一点，即零向量。故我们考虑 $m > n$ 的情形。

为寻找 $null(A) inter ZZ^m$ 的基，我们计算 $A^T$ 的 Hermite normal form $H$ 及其对应的素模矩阵 $U$。于是 $U A^T = H$，故 $A U^T = H^T$。

由于 $U$ 可逆，我们可知 $rank(A) = rank(H)$，记为 $r$。由于 $H$ 为上三角形，其末 $m - r$ 行必全为零。于是 $U^T$ 末 $m - r$ 列 $bf(u)_(r+1), dots, bf(u)_m$ 为整数，且满足 $A bf(u)_j = H^T_(:, j) = 0$，故位于零子空间。向量 $bf(u)_(r+1), dots, bf(u)_m$ 彼此线性无关，共 $m - r$ 个，等于零子空间的维数。故它们构成 $null(A) inter ZZ^m$ 的基。

#include "../diagrams/int-basis.typ"

@int-basis 以图形方式展示了该过程。在实际实现中我们只需第一次转置，因为读取 $U^T$ 的列等价于读取 $U$ 的行。

=== 寻找特解 <find-part-sol>

虽然 Hermite normal form 能解方程组 $A bf(x) = 0$，却不足以解 $A bf(x) = bf(c)$。因此我们转用 _Smith normal form_（史密斯规范形）来寻找特解。

整数矩阵 $A$ 的 _Smith normal form_ 是一个矩阵 $D$，满足如下性质：

- 存在两个素模矩阵 $U$ 与 $V$，使得 $D = U A V$；

- $D$ 为对角矩阵；

- 对所有 $i$，元素 $D_(i, i)$ 整除 $D_(i+1, i+1)$。

@snf-example 给出了 Smith normal form 的实例。

#include "../diagrams/snf-example.typ"

尽管 FPL 未提供计算 Smith normal form 的过程，但该计算相当标准且与 Hermite normal form 类似。我们将其加入到 FPL。

为寻找 $A bf(x) = bf(c)$ 的特解，我们首先求 Smith normal form $D = U A V$。然后方程可改写为

$
  (U^(-1) D V^(-1)) bf(x) = bf(c)
$

令 $bf(y) = V^(-1) bf(x)$，则 $D bf(y) = U bf(c)$。由于 $D$ 为对角矩阵 $diag(d_1, dots, d_n)$，我们可以轻易解出

$
  d_i bf(y)_i = (U bf(c))_i
$

当 $d_i$ 与 $(U bf(c))_i$ 均为零时，我们令 $bf(y)_i = 0$，任意值均可。

当 $d_i = 0$ 但 $(U bf(c))_i != 0$，或 $d_i$ 不整除 $(U bf(c))_i$ 时，我们可断言无整数解，此时原多面体的整数计数为零。

则我们的特解为 $bf(x) = V bf(y)$。

=== 参数化投影

一个 _参数化_ 多面体包含一个未知参数向量 $bf(p)$，出现在其定义约束中。我们考虑如下形式的多面体：

$
  P = { bf(x) | A bf(x) = B bf(p) + bf(c), D bf(x) <= E bf(p) + bf(f)}
$

投影过程与非参数化情形相同。我们求 $null(A)$ 的基矩阵 $V$，它不涉及参数。然后说明寻找 $A bf(x) = B bf(p) + bf(c)$ 特解 $bf(x)_0(bf(p))$ 的方法。

我们首先按 @find-part-sol 中的相同步骤进行。这将导出

$
  d_i bf(y)_i = (U B bf(p) + U bf(c))_i
$

不同于非参数化情形，此处我们不知道 $d_i$ 是否整除分子。因此我们必须在 $bf(p)$ 上施加约束以保证 $bf(y)_i$ 的整数性。

有两大类约束。

当 $d_i = 0$ 时，这给出一个 _equality_（等式）约束，因为它强制 $bf(p)$ 某些分量之间相等。此时 $bf(y)_i$ 可取任意值，故将其设为零。

当 $d_i != 0$ 且它不整除 $U B$ 与 $U bf(c)$ 的每个分量时，这是一个 _modular_（模）约束：即 $U bf(c) - U B bf(p)$ 必须被 $d_i$ 整除。为建模此类约束，我们引入一个 local 变量 $e$，并将有效的 $bf(p)$ 集合写为

$
  { bf(p) | exists e in bb(Z), #h(6pt) U B bf(p) - d_i e + U bf(c) = 0 }
$

$bf(y)_i$ 的解将是 $(U B bf(p) + U bf(c)) / d_i$，因此含有分数系数。由于 FPL 提供任意精度分数与分数矩阵，这对我们的实现不构成问题。

此外，投影过程通过对等式两边乘以分母的最小公倍数（LCM），将此类分数约束转化为整数约束。由于 $bf(p)$ 上的约束保证了 $bf(y)_i$ 的整数性，该方法不会引入那些满足整数约束但不满足分数约束的额外 $bf(y)_i$ 取值。

事实上，所有 $bf(p)$ 上的约束共同构成一个带存在变量的另一个整数关系。该约束关系随后在整个计算中携带，并在 @incl-excl 的求和阶段中纳入考量。

=== 切锥识别 <tangent-cone>

如 @cones 所述，_tangent cones_（切锥）由顶点处的活跃不等式构成。我们对 FPL 中识别切锥的过程提出一个修正。

对含 $m$ 个不等式的 $n$ 维多面体，FPL 过程枚举所有 $binom(m, n)$ 个 $n$ 个不等式的组合。对每组选择，FPL 随后计算一个使它们全部活跃的点。当该点在多面体内时，即为顶点，故由所选不等式构成的锥是切锥。

@fpl-tangent-cone 展示了该算法在二维多面体上的操作。

#include "../diagrams/fpl-tangent-cone.typ"

然而该过程在超过 $n$ 个不等式在同一顶点处活跃的情形下会失败。以 @fpl-cone-failure 中的四棱锥为例。

#include "../diagrams/fpl-cone-failure.typ"

在 @fpl-cone-failure 中，顶点处会识别出四个切锥。金字塔的蓝色、红色与绿色面分别作为每个锥的活跃不等式三元组被选取。然而由于切锥由顶点处所有活跃不等式构成，顶点处应只有一个切锥，即金字塔本身。

为修复该问题，我们遍历约束并检查每个枚举中是否存在其他活跃不等式。若存在，就将其加入切锥。顶点去重以避免重复处理同一锥。例如，若不去重，@fpl-cone-failure 中的顶顶点会产生四个相同的切锥，而实际上应只有一个。

形式上，对参数化多面体

$
  P = { bf(x) | A bf(x) + B bf(p) + bf(c) >= 0 }
$

及其顶点 $bf(v) = X bf(p) + bf(y)$，$bf(v)$ 位于 $P$ 内的条件是

$
  (A X + B) bf(p) + A bf(y) + bf(c) >= 0
$

要识别 $bf(v)$ 处活跃的不等式，我们寻找 $A X + B$ 第 $i$ 行与 $A bf(y) + bf(c)$ 第 $i$ 项全为零的索引 $i$。该做法有效，因为参数空间被期望为满维，故一个不等式要对所有 $bf(p)$ 恒为 $0$，其系数必须全为零。

约束 $(A X + B) bf(p) + A bf(y) + bf(c) >= 0$ 在 $bf(p)$ 上构成一个多面体，称为切锥的 _active region_（活跃区域），因为它标出锥有效的（_active_）区域。我们随后将活跃区域与切锥组成的二元组作为该过程的返回结果。

=== 素模分解 <unimod-decomp>

给定 $n$ 维切锥 $C$，我们的下一步是将其对偶 $dual(C)$ 分解为素模锥。如 @barvinok-alg-overview 所述，我们分解 $dual(C)$ 而非 $C$，以避免在分解中处理低维锥的额外工作。通过分解 $dual(C)$，所有低维锥均可舍弃。

设 $dual(C)$ 的生成元为 $V = display(mat(bf(v)_1, dots, bf(v)_n))$。$dual(C)$ 可能有超过 $n$ 个生成元，此时需要预处理：见 @triangulation。

我们遵循 @LaTTE 中的算法 5。我们计算一个向量 $bf(z)$ in $dual(C)$，使其在范数 $L^infinity$ 意义下短于所有 $bf(v)_i$，并将 $dual(C)$ 分解为 $n$ 个锥 $K_1, dots, K_n$，其中 $K_i$ 由用 $bf(z)$ 替换 $dual(C)$ 第 $i$ 个生成元得到。显式地，$K_i$ 的生成元为 $bf(v)_1, dots, bf(v)_(i-1), bf(z), bf(v)_(i+1), dots, bf(v)_n$。我们对每个 $K_i$ 重复该过程，直到每个生成的锥都是素模锥。

寻找最短向量 $bf(z)$ 时，我们采用 @Grötschel1988 建议的方法。我们应用 Lenstra-Lenstra-Lovász（LLL）算法#footnote[This algorithm is provided by FPL.]计算 $V$ 的一个约化基，并取最短的行向量作为 $bf(z)$。值得注意的是 LLL 并不保证 $L^infinity$ 意义下的精确最短向量，故可能出现 $|bf(z)| > |bf(v)_i|$。但在我们的测试用例中这从未发生。

更稳健的做法是在约化基的线性组合上搜索。由于先前启发式方法被证明效果良好，我们的 Barvinok 实现不包含该搜索步骤。

多面体是否参数化不影响上述过程。对偶锥 $dual(C)$ 的生成元由切锥 $C$ 的 H 表示决定，而在参数的活跃区域内它是固定的。

=== 三角剖分 <triangulation>

对具有生成元 $bf(v)_1, dots bf(v)_m$ 的 $n$ 维锥 $dual(C)$ 执行素模分解前，我们必须保证 $n = m$。若 $m > n$，我们须先对 $dual(C)$ 进行 _triangulate_（三角剖分），将其分解为若干含 $n$ 个生成元的锥。

我们实现 Delaunay 三角剖分。首先将每条射线 $bf(v)_i = (v_0, dots, v_n)$ 提升为 $(n+1)$ 维点

$
  bf(w)_i = (v_0, dots, v_n, sum_(i=0)^n v_i^2)
$

所有点 $bf(w)_i$ 连同原点，在 $(n+1)$ 维空间中构成一个新多面体。经过原点且为多面体面（facet）的那些面，必同时经过另外 $n$ 条射线 $bf(w)_k$；投影回 $n$ 维后，由该面产生的三角剖分锥即为 $bf(v)_k$。这是因为这些锥之间除边界外不相交；此外它们覆盖了整个 $dual(C)$。

@triangulate-example 给出了提升过程的图形示例，尽管对象并非锥。可视化必须使用二维锥，但二维锥从不要求三角剖分。然而该算法可对任意多面体进行三角剖分，不限于锥。

左侧是待三角剖分的多面体，右侧红色点为落在抛物线上的提升点。红色边构成提升后的多面体。

#include "../diagrams/triangulate-example.typ"

我们说明面的计算方式。我们枚举 $bf(w)_k$ 的所有 $n$ 元子集，计算经过它们及原点的超平面的法向量 $bf(n)$。若所有其他点 $bf(w)_j$（$j != k$）都在该平面的同一侧，即 $bf(w)_j dot bf(n)$ 对所有 $j$ 同号，则该超平面就是一个面。否则不是。

这 $n$ 个向量 $bf(w)_k$ 可能线性相关，此时我们提出的方法因不存在唯一的法向量 $bf(n)$ 而失败。为避免此问题，我们对向量加一个微小扰动。向量先乘以一个很大的数#footnote[In our test cases, $10^6$ would be enough. For a more robust implementation, the magnitude should be adjusted to the maximum element in $bf(w)_k$.]，然后向每个向量 $bf(w)_k$ 加上 $k$。

存在一种更高效的面查找算法，称为 _double description method_（双描述法）。但我们的项目未实现它，因为三角剖分过程很少被调用，进一步优化的优先级因此较低。

=== 室分解 <chamber-decomp>

如 @tangent-cone 所述，每个切锥关联一个活跃区域。随后切锥被分解为素模锥，从中计算生成函数，如 @barvinok-overview 所示。

为计算各生成函数在不同参数值下的贡献，我们必须根据活跃区域分割整个参数空间。这由 Clauss-Loechner 算法 @ClaussLoechner 实现，该算法执行 _chamber decomposition_（室分解）。我们发现 FPL 实现中的一个 bug 并修复了。

原始实现可最好地用 FPL 中以下引语概括：

#quote(block: true, attribution: [comment in `Barvinok.cpp`])[
We maintain a list of pairwise disjoint chambers and the generating functions. We iterate over the region list. For each active region $R_j$ (corresponding to the generating function $f_j$), we examine all the current chambers $R_i$.

If $R_j$ has a full-dimensional intersection with an existing chamber $R_i$, then that chamber is replaced by two new ones:
+ the intersection $R_i inter R_j$, where the generating function is $f_i + f_j$;
+ the difference $R_i - R_j$, where the generating function is $f_i$.
]

如注释所述，FPL 仅当当前室 $R_i$ 与活跃区域 $R_j$ 有满维交时才分割室，这由 @LaTTE 证明是合理的。然而问题在于，满维性检查在 $bb(Z)^n$ 中执行，而应当在 $bb(R)^n$ 中执行。

该差异最好用例子说明。考虑如下带两个整数参数 $N$ 与 $M$ 的 1 维多面体 $P subset.eq bb(Z)$，由 $i in bb(Z)$ 上的三个不等式定义：

$
  & 2i <= M <= 2i + 1, &#h(1em);(1)\
  & 2i >= N + 1, &#h(1em);(2) \
  & 2i + N - 2M + 2 >= 0 &#h(1em);(3) \
$

由不等式 (1) 与 (2) 可得 $N + 1 <= M$。由 (2) 与 (3) 可得 $M <= N + 3/2$。故 $(N, M)$ 的活跃区域为

$
  R = {(N, M) | N + 1 <= M <= N + 3/2 }
$

当 $M$ 与 $N$ 为实数时，关系 $R$ 是满维的。然而由于 FPL 只处理整数关系，它总是将 $M$ 与 $N$ 视为整数，并将活跃区域简化为

$
  R_bb(Z) = {(N, M) | M = N + 1}
$

关系 $R_bb(Z)$ 非满维。由于这一错配，FPL 丢弃了本应考虑的区域。

若我们以有理关系操作替换所有整数关系操作，问题即可解决。为避免重写整个库以支持有理数，我们构造一个从有理关系到整数关系的嵌入，该嵌入保持集合并、交与差。

为将有理关系 $R = { bf(x) in bb(Q)^n | A bf(x) + bf(b) >= 0 }$ 表示为整数关系，我们引入一个额外整数变量 $d -> +infinity$，其被解释为公分母。该关系则嵌入为 $R' = { (bf(x)', d) in bb(Z)^(n+1) | A bf(x)' + bf(b) d >= 0 }$，其中 $bf(x)'$ 表示 $d bf(x)$。

随后我们像处理普通整数关系一样对其执行差与交运算。将有理数四舍五入为整数的简化只影响常数项，而不影响 $d$ 的系数 $bf(b)$。

室分解后，我们获得如下形式的室列表：
$
  S' = {(bf(x)', d) in bb(Z)^(n+1) | A bf(x)' + bf(b) d + bf(c) >= 0 }
$

为将它们转换回整数关系，我们注意到 $d -> +infinity$，故两边除以 $d$ 后只有 $bf(c)_i$ 的符号有意义。

对不等式 $A_(i, :) dot bf(x)' + bf(b)_i d + bf(c)_i >= 0$：

- 若 $bf(c)_i < 0$，降为 $A_(i, :) dot bf(x) + bf(b)_i >= 1$；

- 若 $bf(c)_i >= 0$，降为 $A_(i, :) dot bf(x) + bf(b)_i >= 0$。

=== 求和 <incl-excl>

我们已讨论了单个参数化多面体 $P = { bf(x) | A bf(x) + B bf(p) + bf(c) >= 0 }$ 的活跃区域列表及其生成函数的计算方法。然而在我们的缓存缺失计数分析中，必须计数整数关系内部的整数点，而整数关系可以是若干多面体的并。因此我们需要 inclusion-exclusion（容斥）。

考虑整数关系 $union.big_(i=1)^m P_i$。对每个子集 $cal(P) subset.eq {P_i}$，我们计算 $inter.big cal(P)$ 的活跃室与生成函数列表 $(R_cal(P), f)$，连同参数约束 $C_bf(p)$。生成函数 $f$ 的活跃区域即为 $R = R_cal(P) inter C_bf(p)$。由于多面体的交仍为多面体，只需应用前面各节所述方法。

我们依赖 FPL 将生成函数 $f$ 在 $bf(x) = 1$ 处求值，获得关于参数 $bf(p)$ 的、给出整数计数的 quasi-polynomial $q$。我们记录每个三元组 $(cal(P)_j, R_j, q_j)$，其中 $q_j$ 在 $bf(p) in R_j$ 时有效。

随后我们在有效参数区域 $R$ 列表上对参数空间执行室分解。该过程与 @chamber-decomp 中描述的 Clauss-Loechner 算法类似，但不可省略低维交集。它产生一组室 $C_i$，使得对任意区域 $R_j$，每个室要么完全在其中，要么完全在其外。

对分解后的每个 $C_i$，我们遍历所有记录 $(cal(P)_j, R_j, q_j)$。现在 $C_i$ 要么 $R_j$ 的子集，要么与之完全不交。在前者情形，按容斥原理，该室的整数计数增加 $(-1)^(|cal(P)_j|+1) q_j$。在后者情形，计数不变。

这完成了参数化 Barvinok 算法，其结果为参数区域列表以及每个区域内的整数计数函数。

== 优化 <optimisations>

=== 缓存室归属 <cache-ownership>

在 @incl-excl 中，我们说明要计算多面体并内部的整数计数，首先需要将参数空间分解为室 $C_i$，然后检查每个区域 $R_j$ 是否是它的超集。

超集检查涉及空性测试（emptiness test），开销较大。我们可以将结果预计算到分解过程中，从而去除该检查。除了将全域分解为室 $C_i$，我们还计算二元组 $(C_i, bf(b)_i)$，其中 $bf(b)_i$ 是一个位向量（bitvector）。这里 $bf(b)_(i j) = 1$ 表示 $R_i$ 是 $R_j$ 的子集，$bf(b)_(i j) = 0$ 表示二者不交。

分解的每一步中，我们枚举活跃区域 $R_j$，将每个室 $C_i$ 分裂为 $C' = C_i inter R_j$ 与 $C'' = C_i - R_j$。我们知道 $R_j$ 对前者有贡献而对后者没有，故可将 $bf(b)'_j$ 设为 $1$、将 $bf(b)''_j$ 置 $0$，其他条目则从与 $C_i$ 关联的 $bf(b)_i$ 拷贝。

=== 早期消除空关系 <early-removal>

在 @comp-miss-count 中，我们调用 FPL 过程计算一个 presburger relation 的字典序最大值。

该过程首先为每个 disjunct（析取分量）计算一个分段仿射函数，然后将其并成一个单一函数。两个分段函数的并通过枚举所有 piece 对 $(R_i, f_i)$ 与 $(S_j, g_j)$ 实现。算法随后计算区域 $T = { bf(x) | f_i(bf(x)) lexge g_j(bf(y)) }$，并将区域分为 $R_i inter T$ 与 $R_i - T$。最坏情况下，并后的 piece 数量随析取分量个数呈指数增长。

然而我们注意到，通过差或交构造出的大多数关系实际上是不可行的（infeasible）。我们在它们出现时就去除这些区域，使其不再参与并操作、不再导致指数行为。对测试用例而言，尽管 piece 数量仍呈指数增长，但经我们的优化后缩放速度显著变缓（见 @eval-early-removal）。

=== 并行化 <parallel>

如 @Falcon 所述，我们的缓存模型分别处理每个 sink（汇）语句，且该过程是只读的。因此该模型天然并行（embarrassingly parallel），我们可借此并行性获得 3.9 倍加速，如 @eval-parallel 所示。
