== Achievements

The project is a success, as it met all success criteria and implemented several optimisations as extensions.

We built a static analysis pass and several preprocessing passes to predict cache miss counts (@preprocess, @cache-model), capturing the asymptotic behaviour of real cache misses (@accuracy). We optimised it (@optimisations) so that its performance is comparable to collecting cache miss data during execution for our test cases (@performance). We proposed fixes and added new features to the FPL library in MLIR, including critical parts of Barvinok's algorithm (@barvinok-impl).

== Future Work

=== Modelling Spatial Locality

As demonstrated in @accuracy, the current weakness of our implementation is that it only scales to practical programs when the cache line size $L = 1$, and thus fails to model spatial locality. It is capable of capturing asymptotic behaviour, but not the exact miss count.

Although the analysis is capable of processing an arbitrary $L$, it times out for the smallest program in our dataset. When the cases for $L > 1$ are optimised to run in reasonable time, we expect our analysis not only to model scaling trends, but also to predict the absolute counts.

=== Further Optimisations

Despite the 1.21x speedup over counting cache misses during execution, our model is still significantly slower than the reference implementation, Falcon. Opportunities for optimisation include transprecision support in FPL, a faster Barvinok implementation, and pruning disjuncts before the final counting step.

=== Upstreaming

The project is based on FPL and Clang IR, and we plan to integrate it into the upstream codebase. We expect this upstreaming to enable developers to analyse cache behaviour in their programs, to attract a wider audience to polyhedral analysis techniques, and to strengthen the infrastructure for mathematical operations in MLIR.

Due to the complexity of the project and the difficulty of the underlying mathematical concepts, upstreaming will be challenging. Nevertheless, we are actively collaborating with the MLIR community to make progress.

== Reflections

Although I have engaged in projects of similar scale and duration before, this project proved challenging due to the significant complexity of the underlying mathematical theories. Despite careful research on relevant materials when writing the project proposal, I underestimated the amount of knowledge I needed to acquire in order to implement the analysis. However, this additional need did not delay the project. Most of the extra material was understood incrementally and modularly, as the parts of the algorithm were implemented one at a time; I also focussed only on the information relevant to my implementation, rather than on the details of mathematical proofs.

Prior to the project, I also assumed that the foundational mathematical library, FPL, would be fully correct, as it appeared mature and had been integrated into the MLIR infrastructure. During the project, I realised that some under-exercised code paths still contain subtle bugs. In retrospect, I should remain cautious when relying on existing infrastructure: while such components are generally reliable, it is important to take bugs in the library into consideration.
