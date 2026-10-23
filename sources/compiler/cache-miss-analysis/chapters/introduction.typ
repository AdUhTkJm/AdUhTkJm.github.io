In this dissertation, we present a static analysis pass that estimates the number of cache misses using a polyhedral model. We also describe fixes and extensions made to the underlying mathematics library, the Fast Presburger Library (FPL). We then evaluate the accuracy and performance of our approach on a suite of benchmark programs, highlighting possible future optimisations.

== Background

Loops are a primary target for compiler optimisation. Modern compilers apply techniques including loop unrolling, vectorisation and instruction scheduling, which focus on accelerating individual loop iterations by utilising instruction-level parallelism. However, cross-iteration properties such as cache behaviour cannot be captured by these traditional optimisation passes.

In _polyhedral analysis_, loop iterations are modelled as integer points in a high-dimensional space. Relationships between iterations can therefore be represented as integer relations, enabling precise reasoning about memory access patterns.

== Motivation

When writing high-performance programs, developers typically need to perform loop transformations, either manually or by relying on compiler tools. Both approaches require tuning various parameters, such as the block size for loop tiling, in order to achieve good cache locality.

A widely used approach is performance-guided optimisation (PGO). It finds nearly optimal parameters by executing the program on hardware, profiling it, and analysing its performance data, which is time-consuming. Moreover, the process must be repeated across different architectures, making it less suitable for cross-compilation.

Our static cache miss analysis can address these limitations. By utilising mathematical tools that aggregate cache counts into generating functions, the analysis avoids repeatedly running benchmark programs and can be parameterised for different cache sizes.

== Relation to Previous Work <prevwork>

Our analysis is a re-implementation of the Falcon cache model @Falcon as a pass in the Clang IR project, replacing the Integer Set Library (_isl_) with the Fast Presburger Library (_FPL_) @FPL. The project is based solely on the published algorithm in the paper, as the original implementation relies on _isl_ support that is not available in FPL. The algorithm will be explained in detail in @cache-modelling.

FPL is an integer programming library inside MLIR. It provides integer relations and their operations: intersection, union, subtraction, and emptiness testing. As part of this work, we completed Barvinok's algorithm in FPL, and identified and fixed several correctness issues in the library.

The re-implementation is expected to lower the barrier for the MLIR community to utilise polyhedral analysis. Historically, most polyhedral optimisations have lived in separate compiler systems and required non-trivial IR conversion. Our work allows polyhedral analysis to integrate seamlessly with existing MLIR frontends, and we expect it to be a first step towards first-class polyhedral optimisation support in MLIR.
