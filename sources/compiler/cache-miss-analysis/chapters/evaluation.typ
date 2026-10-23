#import "common.typ": *

== Experimental Setup

We conduct our tests on Polybench @Polybench, a collection of 30 computational programs written in C. They have dense numerical kernels, regular loop structures, and are relatively small in size, making Polybench an ideal choice for our evaluation. Among the programs, 28 are _affine programs_ as defined in @req-analysis, and two test cases contain data-dependent control flow, namely `nussinov.c` and `floyd-warshall.c`. The control flow involved is in fact a `min` or `max` function, and even though in theory it could be eliminated with CSE optimisations, this would require more complicated analysis and is out of scope for our project.

The programs have configurable dataset sizes, among which we use small and large datasets in the following sections. Small sizes are mainly used to establish correctness, whereas large ones are used for performance analysis.

We run the tests on Windows Subsystem for Linux (WSL) for development consistency, except that hardware cache miss counts are collected on a native Ubuntu operating system to ensure accuracy. We conduct all tests on an AMD Ryzen 9 7945HX CPU with 16 cores and 512 KB of L1 data cache.

Our implementation is compiled as a release build of LLVM with the default configuration. Specifically, the build flags include `-O3`, and assertions and link-time optimisation (LTO) are both disabled.

== Correctness <correctness>

We demonstrate correctness by comparing our results with those of the original implementation of Falcon @Falcon on 28 Polybench programs. The reference implementation directly takes the `affine` dialect as input. Its test suite already provides the MLIR kernels of the programs, skipping array initialisation and result printing. We modify our input files (C source code) accordingly.

In one test case, `adi.c`, the MLIR input to Falcon involves a CSE optimisation that merges two loads, which affects the cache miss count. To ensure equivalence of inputs, we manually de-optimised it to match the form generated in Clang IR.

We confirmed an exact match of cache miss counts on all 28 programs, given cache line size $L = 1$, cache sizes $C = 64, 128$ for small datasets, and $C = 524288$ for large datasets. This indicates behavioural equivalence under the tested affine programs and cache parameters, and provides strong empirical evidence for the correctness of our implementation.

For $L > 1$, we confirmed an exact match of miss counts on a single hand-crafted small program. However, the analysis times out after 600 seconds even for the smallest program in Polybench, and we cannot obtain further results.

== Accuracy <accuracy>

We measure our model accuracy by comparing its predictions on Polybench programs with miss counts measured with the Unix tool `perf`. We use large datasets to ensure that the working sets of most programs do not fit in the relatively large cache; otherwise, there will be no capacity misses and the corresponding part of our model will remain unevaluated.

We currently assume that each cache line contains a single element. In fact, each cache line is 64 bytes under our setting and contains 8 elements for the test programs. To compensate for the mismatch, we instead set the cache size input to our model to be 8 times larger, which is 4 MB. The cache would then hold the same number of elements, but spatial locality would be completely lost. Therefore, we expect high relative error but strongly correlated scaling behaviour.

The comparison is shown in @miss-cmp, where the $x$ axis is the prediction of our static analysis, the $y$ axis is the hardware measure, and the dotted line denotes $y = x$. The left plot is on a log scale and the right plot is on a linear scale.

#include "../diagrams/miss-cmp.typ"

The absolute counts are nearly completely uncorrelated, yet the scaling trend is largely captured by our model.

It is worth noting that the lack of correlation in the linear case is partly due to large outliers (`gemm.c`, `jacobi-2d.c`) that dominate the error, and it is therefore beneficial to look at the relative prediction error for each individual test case.

=== Relative Error Analysis

@relerror-cdf plots the cumulative distribution function of relative error for our test cases.

The relative error of the prediction results has a geometric mean of $62.37%$ and a median of $78.08%$, confirming that the model gives only highly approximate miss counts under the assumption that $L = 1$.

The maximum error reaches $673.8%$ for `gemm.c`, a naive implementation of matrix multiplication. Its working set is nearly exactly 4 MB in size, which is as large as our input cache size. In extreme cases like this, any model difference, such as ignoring spatial locality, can have a huge impact on cache behaviour.

#include "../diagrams/relerror-cdf.typ"

== Performance <performance>

We compare the running time of our model with that of the reference Falcon implementation and with the execution time of the programs. We also measure the improvements from our optimisations as described in @optimisations.

=== Running Time Comparison

Our model's running time compared to Falcon and the execution time for Polybench programs with large datasets is shown in @time-cmp. Both our model and Falcon are run with 32 threads, which is the result of `nproc` and uses the full CPU capability.

Our implementation is faster than actual execution by 1.21x on average, demonstrating that it is efficient enough to analyse practical programs.

The model is slower than Falcon by 22.1x (geometric mean). We traded efficiency for MLIR integration, as we replaced the highly optimised _isl_ and _barvinok_ libraries in Falcon with FPL and a custom implementation of Barvinok's algorithm. We therefore expect fewer algorithmic and low-level optimisations, and hence such a slowdown.

#include "../diagrams/time-cmp.typ"

The slowdown also suggests room for future optimisation, which we examine in detail in our hotspot analysis (@hotspot).

=== Hotspot Analysis <hotspot>

The hotspot analysis we present in this section reflects the performance of our current implementation. Prior to this, we have iteratively performed similar analyses and addressed multiple bottlenecks. The details are given in @optimisations, and the effects of these optimisations are introduced in @opt-eval.

According to @cache-model, our algorithm is divided into 4 parts: computing $deps(S(bf(x)))$, obtaining the compulsory miss count, computing $dist(S(bf(x)))$, and obtaining the capacity miss count. @time-breakdown shows the percentage of time consumed by each part of our algorithm in a single-threaded setting.

#include "../diagrams/time-breakdown.typ"

We notice that the final counting step for capacity misses takes up 40%-100% of the running time; this step invokes parametric Barvinok's algorithm on unions of polyhedra. We now look more deeply into the performance of the algorithm.

#include "../diagrams/barvinok-time-breakdown.typ"

As mentioned in @incl-excl, the algorithm consists of three parts, namely inclusion-exclusion, chamber decomposition, and summation. We plot a percentage breakdown of the time spent in each step in @barvinok-time-breakdown under different numbers of disjuncts. We find that the most time-consuming step is inclusion-exclusion regardless of the disjunct count.

The hotspot analysis suggests that future optimisation efforts for our model should focus on Barvinok's algorithm, and especially the inclusion-exclusion part, which dominates the running time. This is expected, since in the worst case, the number of records it produces can be exponential in the number of disjuncts. Nevertheless, in our static analysis, we do not encounter such pathological cases: the record count scales approximately quadratically with the disjunct count, as shown in @barvinok-region, suggesting that our current model is tractable for real-world programs. The curve is fitted with `np.polyfit`.

#include "../diagrams/barvinok-region.typ"

One optimisation opportunity would be to reduce the number of disjuncts passed to the final counting step, by pruning certain statements based on easy-to-compute criteria when constructing reuse instances between $S(bf(x))$ and its dependency $T(bf(y))$. Due to the quadratic scaling, this optimisation would be rewarding.

== Optimisation Effects <opt-eval>

=== Caching Chamber Ownership <eval-barvinok-cache>

#include "../diagrams/barvinok-cache-opt.typ"

By caching chamber ownership as described in @cache-ownership, we accelerated the final summation step by 5.32x and made the Barvinok step 23% faster, measured by geometric mean. @barvinok-cache-opt compares the time spent in summation before and after our optimisation.

=== Early Removal of Empty Relations <eval-early-removal>

By removing infeasible regions when unioning two piecewise affine functions, we relieved the exponential growth of the piece count, reducing the base of the exponential.

It is impractical to obtain the full piece count for the unoptimised algorithm, as the program times out after 600 seconds even when unioning 8 functions. Empirically, the piece count grows to about 16,000 after unioning 6 functions.

After our optimisation, the base of the exponential growth has been reduced to 1.22 on Polybench, as shown in @piece-count. Specifically, for 6 disjuncts, the average piece count drops from 16,000 to 31.5. This optimisation enables our analysis for more complicated stencils in Polybench, where the number of disjuncts easily exceeds 10, and the number of functions to union remains equal to the number of disjuncts (see @early-removal).

#include "../diagrams/piece-count.typ"

=== Parallelism <eval-parallel>

#include "../diagrams/time-cmp-parallel.typ"

We exploited task parallelism, where the computation of the cache miss count for each statement is independent. This brings a 3.9x speedup for our test cases in terms of geometric mean, as shown in @time-cmp-parallel.

Since our test cases are run with 32 threads, it would be surprising for the speedup to be less than 4 times. The reason is that no Polybench program has more than 32 array access statements, so the running time for a program is determined by the longest-running statement. For a statement $S$, the disjunct count of $dist(S(bf(x)))$ is the main metric that determines the running time, as shown in @hotspot, and it can vary widely between statements. In stencils, a single statement dominates runtime and the speedup is low; in linear algebraic kernels, the disjunct counts of statements are similar, so they experience greater speedup.

== Summary

Throughout this chapter, we have seen that our analysis captures the asymptotic behaviour of cache miss counts, and does it faster on average than collecting the counts by running the test programs on hardware. We analysed the current hotspot of the analysis to guide future optimisations. We evaluated several of our optimisations and demonstrated its potential to scale to real-world-sized programs.
