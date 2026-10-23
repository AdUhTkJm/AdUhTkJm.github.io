#import "common.typ": *
#set math.mat(delim: "[")

== Workflow Overview

Our analysis is based on the Clang IR project, which is both a C frontend and an MLIR dialect. Its workflow is summarised in @workflow.

#include "../diagrams/workflow.typ"

We start from Clang IR, and raise it partially into Affine IR. This step identifies induction variables and their iteration domain, facilitating later analysis.

Once in the raised IR, we model array indices that result in cache misses as integer points in polyhedra. This is done by analysing array access operations inside loops, computing symbolic representations of the subscripts and forming presburger relations.

Finally, we apply Barvinok's algorithm to count the integer points inside the polyhedra, which yields the estimated cache miss count.

== Repository Overview

@repo-overview is an overview of our modifications made to the Clang IR repository. For clarity, we omitted shell scripts used in development and minor changes that are fewer than ten lines. New files introduced to the repository are highlighted in blue in the diagram.

Our changes are tied to the three-stage workflow described in the previous section. The code is structured for a clear separation between the stages, with each stage lying in independent source files.

#include "../diagrams/repo-overview.typ"

In the file `RaiseToAffine.cpp`, we raise Clang IR to Affine IR, as described in @ir-raising. It recognises common for-loop patterns in the C language and translates them into affine loops. It also generates glue IR to integrate two different dialects in the same MLIR module.

The passes in `RevertLICM.cpp`, `FindOffset.cpp` and `ComputeDeps.cpp` execute in this order to model relations between array indices as integer polyhedra. `RevertLICM.cpp` restructures the IR to simplify execution of `FindOffset.cpp`, which then annotates the operations with analysed indices. The last pass `ComputeDeps.cpp` is where relations on array subscripts are translated into polyhedra.

The counting step is implemented in `Barvinok.cpp`, consuming the polyhedra from the modelling step and yields a cache miss count estimation. We completed Barvinok's algorithm in the file based on existing stubs in MLIR.

In addition to these core components, changes are made to existing files in the Clang IR repository, in order to integrate our passes into the MLIR framework and to collect performance data.

Overall, our repository reflects the modular decomposition identified in requirement analysis (@req-analysis), on which we expanded to adjust to the complexity of the project.

== Preprocessing Passes <preprocess>

=== IR Raising <ir-raising>

In this stage, we raise affine loops in Clang IR into the `affine` dialect in MLIR, which enables subsequent passes to analyse loop structures and their induction variables.

We focus on the canonical C loop structure as follows.

```c
for (i = a; i < n; i++)
```

In Clang IR, every global variable is assigned a stack address (a ```mlir cir.alloca``` operation). A loop is generated as a ```mlir cir.for``` operation. The loop has three regions, namely `cond` for the loop condition `i < n`, `body` for the loop body, and `step` for the increment `i++`. The initialisation statement `i = a` is put before the ```mlir cir.for``` operation, as it is executed once only before loop entry.

In order to raise affine loops, we match the pattern shown in @cir-for-op and extract the lower bound ```mlir %a```, upper bound ```mlir %n``` and the induction variable ```mlir %i```. Then we create an ```mlir affine.for``` operation with identical bounds and the same body region.

#include "../diagrams/cir-for-op.typ"

A challenge in the raising is the type mismatch between the loop variable ``` %i``` in Clang IR and loop variable ``` %arg``` in the `affine` dialect. Clang IR has its own type ```mlir !cir.int<s, 32>``` for a signed 32-bit integer, while the `affine` dialect requires the built-in MLIR type `index` for its loop variable. As a result, we cannot directly replace the usage of ``` %i``` to ``` %arg```.

To solve this, we extend Clang IR with a type-conversion operation ```mlir cir.from_index```  that converts the `index` type to the required Clang IR integer type, allowing interoperation between the IRs. Similarly, we introduce a ```mlir cir.index_cast``` operation that casts Clang IR types into `index`.

We also handle reversed loops of the form

```c for (i = a; i >= n; i--)```

We normalise them into an equivalent increasing form

```c for (j = n; j < a + 1; j++) ```

And we replace all uses of `i` inside the loop with `n + a - j - 1`.

The normalisation is crucial to the soundness of lexicographical comparison in the modelling phase, introduced in @comp-miss-count.

=== Finding Offsets and Bases

Accesses to arrays, for example `b[i][j]`, can be decomposed into a _base_ `b` and an _offset_ $(i, j)$. The cache model requires us to find both: the base distinguishes arrays, acting as a basic alias analysis; the offset is used to compute dependency relations. The offsets and bases of array access statements are identified in a preprocessing pass in the file `FindOffset.cpp`.

The access `b[i][j]` is expressed in Clang IR as follows, where multi-dimensional accesses are lowered into a sequence of ```mlir cir.get_element``` operations #footnote[Strictly speaking, Clang IR can generate ```mlir cir.ptr_stride``` operation as well. The operation is similar to `get_element`, and the process of finding offsets and bases is largely unchanged.], each operating on a single dimension.

```mlir
%1 = cir.get_element %b[%i]
%2 = cir.get_element %1[%j]
%result = cir.load %2
```

We examine the defining operation of the operand of `load` (similarly the address operand of `store`), and expect a `get_element %addr[%x]`. We check the depth $d$ of loop nest surrounding the operation, and create an affine expression

$
  c + sum a_i x_i
$

with $c$ and $a_i$ initially set to zero.

The coefficients are computed by recursively climbing up the use-def chain of `%x` and processing arithmetic operations along the way:

- For ```mlir cir.int``` carrying a constant $v$, we increase $c$ by $v$;

- For a value ```mlir %i``` corresponding to $x_i$, we increase $a_i$ by 1;

- For the add/subtraction operations, ```mlir cir.binop add``` (or `sub`), we sum the affine expressions of both its operands;

- For multiplication ```mlir cir.binop mul``` by constant $m$, we scale all coefficients and the constant by $m$.

All other expressions result in a failure, and are rejected by our analysis pass, as they are no longer affine.

In order to find the base, `%addr` is also recursively processed. If `%addr` itself is defined by a `get_element` operation, we recursively examine its address, effectively walking up the address chain until it is either an `alloca` or a global array.

We provide a worked example to demonstrate the process in @offset-example. It is an adapted excerpt from the Clang IR obtained from `ludcmp.c` in Polybench.

#include "../diagrams/offset-example.typ"

Our analysis determines that `%70` accesses the array `A` with offsets $(119 - i, j)$. The base `A` is obtained by looking at the address operand `%69`, and then `%A` (the purple part). Since the `get_element` is located inside two nested loops, we know the offsets are affine functions of two induction variables. The offset of the second dimension is computed by examining `%68`, which is a `from_index` operation that directly references $j$ (the blue part). The offset of dimension 1 is similarly obtained, with an additional `sub` expression before hitting $i$ (the green part).

The pass does not handle accesses through arbitrary pointers, as doing so would require alias analysis, significantly increasing implementation complexity.

Before the pass, we perform constant folding and inlining to simplify the IR and reduce the need of complicated inter-procedural analysis.

The base and offset of each access is expressed in attributes attached to each `get_element` operation.

For bases, we assign an integer as identification to every `alloca` or global array, and attach an `array_base` attribute to the `get_element` operation. This attribute is newly introduced into Clang IR. We cannot directly store operations or SSA values in an attribute, as these are not serialisable in MLIR and will be rejected.

We similarly added the `array_offset` attribute for array offsets. The attribute stores an affine map, which is natively supported in MLIR.

As an example, a `get_element` operation after the pass might look like:

```mlir
%17 = cir.get_element %5[%8] {
  #array_base = 1,
  #array_offset = (d0, d1) -> (d0)
}
```

The 2-dimensional induction vector `(d0, d1)` indicates that the operation is nested in two loops, and that it indexes the array numbered $1$ with the outer loop's induction variable.

=== Restoring Locality of `get_element` Operations

As demonstrated in the previous section, array access information is associated with `get_element` operations, and the dimension of the affine map for offsets is determined by the loop nest in which the operation resides.

Our analysis expects that the `get_element` operation resides in the same loop nest with the access statement, in order to refer to all induction variables in the surrounding loops. However, this is not always true. Consider the IR structure on @revert-licm-example, (a):

#include "../diagrams/revert-licm-example.typ"

The load is nested in two loops and has an induction vector $(i, j)$, but its `get_element` is nested in a single loop and is thought to have induction vector $j$ in our analysis. The dimension mismatch violates our assumptions.

We notice that in code generation, this structure typically does not appear. The `get_element` operations will immediately precede the loads or stores, as shown in @revert-licm-example, (b). The structure arises when the inner `get_element` operation is hoisted out of the loop due to loop-invariant code motion (LICM). Subsequently, common subexpression elimination (CSE) can merge such two operations, further separating them from their usage.

The most straightforward solution to the issue is therefore disabling LICM and CSE in Clang IR. For considerations on future integration into MLIR, we also implemented a `RevertLICM` pass that reverts the process by cloning `get_element` operations, ensuring every load has a `get_element` that directly precedes it.

== Cache Miss Counting Analysis <cache-model>

=== Counting Compulsory Misses <comp-miss-count>

To compute compulsory misses, we identify the set of statement instances whose accessed address has not been accessed before.

We first identify the set of all array access statements, denoted $cal(L)$. A statement $S$ accesses an array if it is a ```mlir cir.load``` or ```mlir cir.store``` operation whose address operand is a ```mlir cir.get_element``` with base and offset attributes attached.

We then assign a positive integer, referred to as the _lexical index_, to each statement in $cal(L)$ according to the order in which it appears in the program, to facilitate lexical-order comparison in later steps. Earlier statements receive smaller indices. We denote the lexical index of $S in cal(L)$ as $i_S$.

We consider each statement $S in cal(L)$ individually. In @dep-compute, we defined the notion of dependency between $S(bf(x))$ and another access operation $T(bf(y))$. We enumerate all $T in cal(L)$ and form the dependency relation:

$
  "depend"(S, T) = {(bf(x), bf(y)) | S(bf(x)) "depends on" T(bf(y))}
$

As defined in @dep-compute, in our cache model, $S$ depends on $T$ if they access the same address and $T$ executes before $S$.

In @fpl, we noted that FPL supports affine constraints only. We now show that the conditions of dependency can indeed be expressed with affine constraints.

The in-bound condition and the condition $S[bf(x)] = T[bf(y)]$ are affine because all loop bounds and array accesses are assumed to be affine.

To ensure that $S(bf(x))$ is executed after $T(bf(y))$, it suffices to require $S(bf(x)) lexge T(bf(y))$, because all loops are normalised into increasing loops as described in @ir-raising. We denote the common loop depth of $S$ and $T$ as $d$. When $S$ and $T$ are in the same loop nest, we construct the lexicographical comparison by definition:

$
  S(bf(x)) lexge T(bf(y)) <==> or.big_(j=0)^(d-1) (bf(x)_j > bf(y)_j and and.big_(i=0)^(j-1) (bf(x)_i = bf(y)_i))
$

When that is not the case, we fall back to lexical order after all common loops have been exhausted. We union the previous relation with the following disjunct only when $T$ is lexically before $S$:

$
  and.big_(i=0)^(d-1) bf(x)_i = bf(y)_i
$

We need to find a statement instance $deps(S(bf(x)))$, the latest, or lexicographically largest, dependency of $S(bf(x))$ among all $T$ that we have examined. As they may reside in different loop nests with different depths, their induction variables are not directly comparable. We have explained how to compare the execution order of two instances $S(bf(x))$ and $T(bf(y))$, but to compare candidates more generally, we must embed the vectors in a common space that encodes both lexical order and loop structure.

We denote by $n$ the maximum nested loop depth among all candidate statements $T$, and define the lexical index of a loop as the smallest lexical index of the statements inside it. Suppose $T(bf(y))$ has lexical index $i_T$ and is nested in loops with indices $i_0, dots, i_m$. We then raise $bf(y) = (y_0, dots, y_m)$ to

$
  bf(z) = (i_0, y_0, i_1, y_1, dots, i_m, y_m, underbrace(#[$i_T, 0, dots, i_T, 0$], n - m "pairs"), i_T)
$

In the embedding, each pair $i_m, y_m$ encodes both the identity of a loop and the corresponding value of the induction variable. The padding $i_T, 0$ denotes the absence of a loop, and is required to maintain the correct lexicographical order between statements at different depths. The final $i_T$ acts as a tie-breaker for statements in the same loop nest.

At first glance, it might seem sufficient to raise $bf(y)$ instead to

$
  bf(z) = (i_0, y_0, i_1, y_1, dots, i_m, y_m, 0, 0, dots, 0, 0, i_T)
$

However, this variant does not work for non-perfectly nested loops, because it lacks lexical-order information for statements outside the loop hierarchy. Consider the following example:
```python
for i:
  for j:
    load a[i]     # T1: index = 1
  load a[j]       # T2: index = 2
```

In this case, if we were to fill in zeroes after $y_m$, we would obtain

$
  bf(x)_(T_1) = (1, i, 1, j, 1) \
  bf(x)_(T_2) = (1, i, 0, 0, 2) \
$

For the same value of $i$, $T_1$ should be lexicographically before $T_2$, but the raised vectors suggest the opposite.

After raising all dependency candidates $T(bf(y))$ into the common space, we use FPL to compute the lexicographical maximum in order to obtain $deps(S(bf(x)))$. The maximisation is piecewise on the domain of $bf(x)$, so FPL returns a list of _pieces_, namely pairs $(D, bf(z)(bf(x)))$ where $bf(z)(bf(x))$ is the raised maximum, expressed as a function of $bf(x)$, and $D$ is the range of $bf(x)$ over which $bf(z)(bf(x))$ is valid. Since $i_T$ is unique, the raising procedure is reversible, and we can lower any $bf(z)(bf(x))$ back to $T(bf(y)(bf(x)))$.

Each $D$ returned by the procedure corresponds to a region where a dependency exists. By subtracting all such $D$ from the iteration domain of $S$, we obtain the region $U$ where the address has not been accessed previously. The integer point count of $U$ is therefore equal to the number of compulsory misses, which can be computed using Barvinok's algorithm.

=== Computation of Reuse Distance

The reuse distance $dist(S(bf(x)))$ is the number of distinct cache lines accessed strictly between $deps(S(bf(x)))$ and $S(bf(x))$. As $deps(S(bf(x)))$ is defined piecewise on the iteration domain of $bf(x)$, we must enumerate all pieces $(D, bf(z)(bf(x)))$ and the lowered statement $T(bf(y))$ computed in the previous section.

As a first step, we collect the statements that can possibly execute between $S(bf(x))$ and $T(bf(y))$, namely all array access statements enclosed in the smallest common region containing both $S$ and $T$. These are not limited to the statements whose lexical indices lie between $i_S$ and $i_T$, because statements after $S$ but still within the same region as $S$ can also execute between $S(bf(x))$ and $T(bf(y))$. A similar observation applies to $T$.

Each collected statement $U$ is associated with an induction vector $bf(w)$. We find the range of $bf(w)$ such that $U$ is executed before $S(bf(x))$ and after $T(bf(y))$. These points are referred to as _reuse instances_. Each such $bf(w)$ corresponds to an instance of $U$ that accesses memory between $S(bf(x))$ and $T(bf(y))$, and contributes to the reuse distance when it maps to a distinct cache line.

Formally,

$
  "reuseInstance"(U, S(bf(x)), T(bf(y))) = { bf(w) | bf(y)(bf(x)) lexle bf(w) lexle bf(x) and bf(w) in cal(D)_bf(w) }
$

Here $cal(D)_bf(w)$ is the iteration domain of $bf(w)$, and $lexle$ denotes lexicographical precedence, as defined in the previous section.

To compute the set of memory locations accessed by $U$, we compose the relation $"reuseInstance"(U, S(bf(x)), T(bf(y)))$ with the access function of $U$, which is an affine map. We then union the composed relations across all $U$, resulting in the total set of memory locations accessed between $S(bf(x))$ and $T(bf(y))$, which we denote as $"total"(S(bf(x)), T(bf(y)))$.

If we assume the cache line size $L$ is 1, we have

$
  dist(S(bf(x))) = \#"total"(S(bf(x)), T(bf(y)))
$

Since the $"total"$ relation is formed by affine equalities and inequalities, it can be viewed as the H-representation of a polyhedron. We can therefore count the integer points inside it using Barvinok's algorithm.

This polyhedron is parametric in $bf(x)$. In this case, the count given by Barvinok's algorithm is not a single integer, but a _quasi-polynomial_ in $bf(x)$. It is of the following form:

$
  sum_(i=0)^n c_i product_(j=0)^m floor(bf(k)_(i j) dot bf(x) + b_(i j))
$

where $c_i$, $bf(k)_(i j)$ and $b_(i j)$ are rational numbers computed by the algorithm. The form is crucial for counting capacity misses, which we introduce in the next section.

=== Counting Capacity Misses <cap-miss-count>

To obtain the capacity miss count for a cache of size $C$, we consider each statement $S in cal(L)$ separately and count the induction vectors $bf(x)$ such that $dist(S(bf(x))) >= C$.

When every product in the quasi-polynomial $dist(S(bf(x)))$ has at most one term, the condition $dist(S(bf(x))) >= C$ can be transformed into a polyhedron, and thus solved efficiently via Barvinok's algorithm. In more general cases, however, even deciding whether such a $bf(x)$ exists is NP-hard @ComputationalComplexity. We therefore have to enumerate $bf(x) = (x_1, dots, x_n)$ to obtain an exact count.

We enumerate dimension by dimension. Given fixed values of $x_1, dots, x_i$, we can determine the range $[l, r]$ of $x_(i+1)$ using the Simplex algorithm. We then iterate through each value $k in [l, r]$, fix $x_(i+1)$ to $k$, and recurse into the enumeration of $x_(i+2)$.

We stop the recursive process whenever the PWMA function has been simplified to at most one term in each product, at which point we invoke Barvinok's algorithm. For performance reasons, if the remaining variables have at most 10 possible values, we continue enumeration instead of calling the more complicated Barvinok procedure.

=== Supporting Configurable Cacheline Sizes <cacheline-size>

In the preceding discussion, we assumed that each array element occupies an entire cache line. We now explain how we support cache-line sizes $L > 1$.

We take a 2-dimensional array `a[N][M]` as an example. An array access `a[i][j]` is equivalent to accessing the address `&a + i * M + j`, which maps to the cache line $floor((i M + j) / L)$. In particular, when we assume that $M$ is a multiple of $L$, we only need to replace the last dimension $j$ with $floor(j / L)$.

However, our support for $L > 1$ is limited. The introduction of floor division, and therefore local variables, leads to longer generating functions and makes enumeration unavoidable. Even for small programs and $L = 3$, our implementation does not terminate within 600 seconds.

== Barvinok's Algorithm <barvinok-impl>

We have provided an overview of Barvinok's algorithm in @barvinok-overview. This section explains the details of our implementation.

=== Non-parametric Projection

We start with a non-parametric $d$-dimensional polyhedron with both inequalities and equalities:

$ P = { bf(x) in bb(Z)^d | A bf(x) = bf(c), D bf(x) <= bf(f) } $

Since Barvinok's algorithm operates on full-dimensional polyhedra, _projection_ is required to find a new $d'$-dimensional polyhedron $Q$ with the same number of integer points as $P$, such that $Q$ spans the entire $bb(Z)^(d')$. This implies that $Q$ cannot have any equalities.

$ Q = { bf(y) in bb(Z)^d' | D' bf(y) <= bf(f)' } $

However, the converse is not true: even if $Q$ has no equalities, it does not necessarily mean that $Q$ is full-dimensional. For example, consider this polyhedron in $bb(Z)^2$:

$
  x - y &>= 0 \
  -x + y &>= 0
$

This clearly indicates an equality $x = y$, so it lies inside a 1-dimensional subspace of $bb(Z)^2$.

We prevent this from happening by preprocessing $P$. For each inequality $D_(i,:) dot bf(x) <= bf(f)_i$, we compute the minimum of $D_(i, :) dot bf(x)$ under the constraints $A bf(x) = bf(c)$ and $D bf(x) <= bf(f)$. This is done using the Simplex algorithm, which is provided in FPL. When the minimum is equal to $bf(f)_i$, we know that this inequality is actually an equality.

Then we aim to eliminate all equalities $A bf(x) = bf(c)$. Consider the _null space_ of $A$, which is defined as

$ null(A) = { bf(x) | A bf(x) = 0 } $

It is a vector space. We find an integer basis that spans the vector space $null(A) inter ZZ^m$: $bf(v)_1, bf(v)_2, ..., bf(v)_n$. They form a matrix:

$ V = mat(bf(v)_1, dots, bf(v)_n) $

Then every solution $bf(x)$ to the system $A bf(x) = bf(c)$ can be written as

$ bf(x) = V bf(y) + bf(x)_0 $

where $bf(x)_0$ is a _particular solution_, i.e. any integer solution satisfying the system.

There is a bijection between $bf(x)$ and $bf(y)$. Moreover, when $bf(y)$ is an integer vector, so is $bf(x)$. The converse also holds: we have $bf(y) = V^(-1) (bf(x) - bf(x)_0)$. As $V$ is unimodular and $V^(-1)$ is therefore an integer matrix, $bf(y)$ is an integer vector whenever $bf(x)$ is. Since the bijection preserves integrality, we can count vectors $bf(y)$ instead of vectors $bf(x)$, as the counts remain the same.

If we denote the number of integer points inside a polyhedron $P$ as $\#P$, then we have

$ \#P
&= \#{ bf(x) in bb(Z)^d | A bf(x) = bf(c), D bf(x) <= bf(f) } \
&= \#{ bf(y) in bb(Z)^(d') | D (V bf(y) + bf(x)_0) <= bf(f) } \
&= \#{ bf(y) in bb(Z)^(d') | underbrace((D V), D') bf(y) <= underbrace(bf(f) - D bf(x)_0, bf(f)') } \
&eq.delta \#Q
$

In this way, we obtain a suitable $Q$ as the result of the projection, with $D' = D V$ and $bf(f)' = bf(f) - D x_0$. We now explain how we find a basis of $null(A)$ and a particular solution $bf(x)_0$.

=== Integer Basis of Null Space

When we find a basis for the null space of a real-valued matrix $M in bb(R)^(n times m)$, we typically reduce $M$ to _row-echelon form_. For an integer matrix $A in bb(Z)^(n times m)$, we need a similar notion that preserves integrality. This leads to the _Hermite normal form_ and _unimodular matrices_.

An integer matrix is _unimodular_ if its determinant is $plus.minus 1$. The inverse of a unimodular matrix is also an integer matrix. This is because

$ M^(-1) = ("adj"(M)) / det(M) $

Here $"adj"(M)$ is the adjugate of $M$. It has integer entries by definition: each of its entries is the determinant of a submatrix of $M$. Therefore, $M^(-1)$ also has integer entries. @unimod-mat-example gives an example of a unimodular matrix and its inverse.

#include "../diagrams/unimod-mat-example.typ"

The _Hermite normal form_ of an integer matrix $A$ is a matrix $H$ with the following properties:

- There exists a unimodular matrix $U$, such that $H = U A$;

- The first non-zero entry on each row, called the _pivot_, is positive whenever it exists;

- $H$ is upper-triangular, meaning the elements below the pivots are zero;

- The elements above the pivots are nonnegative and strictly smaller than the pivot.

@hnf-example gives an example of Hermite normal form.

FPL provides a procedure to compute the Hermite normal form of an integer matrix $M$. It returns both $H$ and $U$.

#include "../diagrams/hnf-example.typ"

For the $n times m$ matrix $A$, when $m <= n$ and $A$ has full column rank, the null space contains a single point, namely the zero vector. We therefore consider the case where $m > n$.

To find the basis of $null(A) inter ZZ^m$, we compute the Hermite normal form $H$ and the corresponding unimodular matrix $U$ of $A^T$. Then $U A^T = H$, so $A U^T = H^T$.

Since $U$ is invertible, we know that $rank(A) = rank(H)$, which we denote by $r$. As $H$ is upper triangular, its last $m - r$ rows must all be zero. Then the last $m - r$ columns $bf(u)_(r+1), dots, bf(u)_m$ of $U^T$ are integers, and they satisfy $A bf(u)_j = H^T_(:, j) = 0$, so they lie in the null space. The vectors $bf(u)_(r+1), dots, bf(u)_m$ are also linearly independent, and there are $m - r$ of them, which is equal to the dimension of the null space. Hence, they form a basis of $null(A) inter ZZ^m$.

#include "../diagrams/int-basis.typ"

@int-basis depicts the procedure graphically. In the actual implementation, we only need the first transposition, as reading off columns of $U^T$ is equivalent to reading off rows of $U$.

=== Finding Particular Solution <find-part-sol>

Although Hermite normal form can solve the system $A bf(x) = 0$, it is not enough to solve $A bf(x) = bf(c)$. We therefore turn to the _Smith normal form_ to find a particular solution.

The _Smith normal form_ of an integer matrix $A$ is a matrix $D$ with the following properties:

- There exist two unimodular matrices $U$ and $V$, such that $D = U A V$;

- $D$ is diagonal;

- For all $i$, the element $D_(i, i)$ divides $D_(i+1, i+1)$.

@snf-example provides an example of Smith normal form.

#include "../diagrams/snf-example.typ"

Although FPL does not provide a procedure to compute Smith normal form, the computation is fairly standard and similar to that of Hermite normal form. We added it to FPL.

In order to find a particular solution to $A bf(x) = bf(c)$, we first find the Smith normal form $D = U A V$. Then the equation can be rewritten to

$
  (U^(-1) D V^(-1)) bf(x) = bf(c)
$

Let $bf(y) = V^(-1) bf(x)$, then we have $D bf(y) = U bf(c)$. Since $D$ is a diagonal matrix $diag(d_1, dots, d_n)$, we can easily solve the equation by

$
  d_i bf(y)_i = (U bf(c))_i
$

When both $d_i$ and $(U bf(c))_i$ are zero, we let $bf(y)_i = 0$, as any value would be acceptable.

When $d_i = 0$ but $(U bf(c))_i != 0$, or when $d_i$ does not divide $(U bf(c))_i$, we can conclude that there is no integer solution, in which case the integer count of the original polyhedron is zero.

Then our particular solution would be $bf(x) = V bf(y)$.

=== Parametric Projection

A _parametric_ polyhedron contains a vector of unknown parameters, $bf(p)$, in its defining constraints. We consider polyhedra of the form

$
  P = { bf(x) | A bf(x) = B bf(p) + bf(c), D bf(x) <= E bf(p) + bf(f)}
$

The projection procedure is the same as in the non-parametric case. We find a basis matrix $V$ of $null(A)$, which does not involve parameters. We then describe our method for finding a particular solution $bf(x)_0(bf(p))$ to $A bf(x) = B bf(p) + bf(c)$.

We first follow the same steps as @find-part-sol. This would lead us to

$
  d_i bf(y)_i = (U B bf(p) + U bf(c))_i
$

Unlike the non-parametric case, here we do not know whether $d_i$ divides the numerator. We therefore have to impose constraints on $bf(p)$ to guarantee the integrality of $bf(y)_i$.

There are two types of constraints.

When $d_i = 0$, this gives an _equality_ constraint, since it forces an equality between entries of $bf(p)$. In this case, $bf(y)_i$ can take any value, so we set it to zero.

When $d_i != 0$ and it does not divide every entry in $U B$ and $U bf(c)$, this is a _modular_ constraint: namely, $U bf(c) - U B bf(p)$ must be divisible by $d_i$. To model such a constraint, we introduce a local variable $e$ and write the set of valid $bf(p)$ as

$
  { bf(p) | exists e in bb(Z), #h(6pt) U B bf(p) - d_i e + U bf(c) = 0 }
$

The solution for $bf(y)_i$ will be $(U B bf(p) + U bf(c)) / d_i$ and will therefore contain fractional coefficients. Since FPL offers arbitrary-precision fractions and a fraction matrix, this does not pose a problem for our implementation.

Moreover, the projection procedure converts such fractional constraints into integer ones by multiplying both sides by the least common multiple (LCM) of the denominators. Since the constraints on $bf(p)$ guarantee the integrality of $bf(y)_i$, this approach does not introduce extra values of $bf(y)_i$ that satisfy the integer constraint but not the fractional one.

All constraints on $bf(p)$ in fact form another integer relation with existential variables. This constraint relation is then carried throughout the computation and accounted for in the summation phase in @incl-excl.

=== Tangent Cone Identification <tangent-cone>

As mentioned in @cones, _tangent cones_ are formed by active inequalities at vertices. We propose a fix to the procedure of identifying tangent cones in FPL.

For an $n$-dimensional polyhedron with $m$ inequalities, the FPL procedure enumerates all $binom(m, n)$ possible combinations of $n$ inequalities. For each choice of inequalities, FPL then computes a point at which they are all active. When the point is inside the polyhedron, it is a vertex, and hence the cone formed by the chosen inequalities is a tangent cone.

@fpl-tangent-cone shows the operation of the algorithm for a 2-dimensional polyhedron.

#include "../diagrams/fpl-tangent-cone.typ"

However, this procedure fails for cases where more than $n$ inequalities are active at the same vertex. Take the quadrangular pyramid in @fpl-cone-failure as an example.

#include "../diagrams/fpl-cone-failure.typ"

In @fpl-cone-failure, four tangent cones would be identified at the top vertex. The blue, red, and green faces of the pyramid are selected as active inequality triples for each cone. However, since the tangent cone is formed by all inequalities active at the vertex, there should be a single tangent cone at the top vertex, namely the pyramid itself.

To fix the problem, we scan through the constraints and check whether there are additional active inequalities in each enumeration. If there are any, we add them to the tangent cone. The vertices are deduplicated to avoid processing the same cone twice. For example, without deduplication, the top vertex in @fpl-cone-failure would result in four identical tangent cones, whereas only one should be present.

Formally, for a parametric polyhedron

$
  P = { bf(x) | A bf(x) + B bf(p) + bf(c) >= 0 }
$

and a vertex $bf(v) = X bf(p) + bf(y)$, the condition of $bf(v)$ lying inside $P$ is

$
  (A X + B) bf(p) + A bf(y) + bf(c) >= 0
$

To identify inequalities active at $bf(v)$, we look for indices $i$ where row $i$ of $A X + B$ and the $i$th entry of $A bf(y) + bf(c)$ are all zero. This is valid because the parameter space is expected to be full-dimensional, so for an inequality to be $0$ for all $bf(p)$, the coefficients must all be zero.

The constraints $(A X + B) bf(p) + A bf(y) + bf(c) >= 0$ on $bf(p)$ form a polyhedron, which is called the _active region_ of the tangent cone, as it denotes the region where the cone is valid, or _active_. We then return the pair consisting of the active region and the tangent cone as the result of the procedure.

=== Unimodular Decomposition <unimod-decomp>

Given an $n$-dimensional tangent cone $C$, our next step is to decompose its dual $dual(C)$ into unimodular cones. As mentioned in @barvinok-alg-overview, we decompose $dual(C)$ rather than $C$ to avoid the extra work of accounting for lower-dimensional cones in the decomposition. By decomposing $dual(C)$, all lower-dimensional cones can be discarded.

We denote the generators of $dual(C)$ as $V = display(mat(bf(v)_1, dots, bf(v)_n))$. It is possible that $dual(C)$ has more than $n$ generators, in which case preprocessing is needed: see @triangulation.

We follow Algorithm 5 in @LaTTE. We compute a vector $bf(z)$ in $dual(C)$ that is shorter than all $bf(v)_i$ with respect to the norm $L^infinity$, and decompose $dual(C)$ into $n$ cones $K_1, dots, K_n$, where $K_i$ is formed by replacing the $i$th generator of $dual(C)$ with $bf(z)$. Written explicitly, the generators of $K_i$ are $bf(v)_1, dots, bf(v)_(i-1), bf(z), bf(v)_(i+1), dots, bf(v)_n$. We repeat the process for each $K_i$ until every resulting cone is unimodular.

To find the shortest vector $bf(z)$, we use the method suggested in @Grötschel1988. We apply the Lenstra-Lenstra-Lovász (LLL) algorithm#footnote[This algorithm is provided by FPL.] to compute a reduced basis of $V$ and take the shortest row vector as $bf(z)$. It is worth noting that LLL does not guarantee the exact shortest vector in $L^infinity$, so it is possible that $|bf(z)| > |bf(v)_i|$. However, in our test cases, this never happens.

A more robust approach would involve searching over linear combinations of the reduced basis. As the previous heuristic proved to work well, this search step is not included in our Barvinok implementation.

Whether the polytope is parametric does not affect the above procedure. The generators of the dual cone $dual(C)$ are determined by the H-representation of the tangent cone $C$, which stays fixed within the active region of the parameters.

=== Triangulation <triangulation>

To perform unimodular decomposition on an $n$-dimensional cone $dual(C)$ with generators $bf(v)_1, dots bf(v)_m$, we must ensure that $n = m$. If $m > n$, we must first _triangulate_ $dual(C)$, decomposing it into several cones with $n$ generators.

We implement the Delaunay triangulation. We first lift each ray $bf(v)_i = (v_0, dots, v_n)$ to an $(n+1)$-dimensional point

$
  bf(w)_i = (v_0, dots, v_n, sum_(i=0)^n v_i^2)
$

All points $bf(w)_i$, together with the origin, form a new polyhedron in the $(n+1)$-dimensional space. The facets of this polyhedron that pass through the origin must also pass through another $n$ rays $bf(w)_k$; when projected back into $n$ dimensions, $bf(v)_k$ is the triangulated cone produced by the facet. This is because these cones do not overlap with one another except on their boundaries; moreover, they cover the entire $dual(C)$.

@triangulate-example provides a graphical example of the lifting, though not for a cone. We must use 2-dimensional cones for visualisation, but they never require triangulation. Nevertheless, the algorithm can triangulate any polyhedron and is not limited to cones.

The left-hand side is the polyhedron to be triangulated, and the red points on the right-hand side are lifted points resting on a parabola. The red edges form the lifted polyhedron.

#include "../diagrams/triangulate-example.typ"

We now explain how the facets are calculated. We enumerate all subsets of $n$ rays $bf(w)_k$, and compute the normal vector $bf(n)$ for the hyperplane that passes through them and the origin. If all other points $bf(w)_j$ ($j != k$) are on the same side of the plane, that is, if $bf(w)_j dot bf(n)$ has the same sign for every $j$, then the hyperplane is a facet. Otherwise, it is not.

It is possible that the $n$ vectors $bf(w)_k$ are linearly dependent, in which case our proposed method fails because there is no unique normal vector $bf(n)$. To avoid this, we add a small disturbance to the vectors. The vectors are first multiplied by a large number#footnote[In our test cases, $10^6$ would be enough. For a more robust implementation, the magnitude should be adjusted to the maximum element in $bf(w)_k$.], and then $k$ is added to each vector $bf(w)_k$.

There is a more efficient algorithm, called the _double description method_, for finding the facets. However, it is not implemented in our project, as the triangulation procedure is rarely called and further optimisation is therefore a low priority.

=== Chamber Decomposition <chamber-decomp>

As mentioned in @tangent-cone, each tangent cone is associated with an active region. The tangent cone will then be decomposed into unimodular cones, from which we compute a generating function, as shown in @barvinok-overview.

In order to compute the contribution of each generating function under different parameter values, we must split the entire parameter space according to the active regions. This is achieved by the Clauss-Loechner algorithm @ClaussLoechner, which performs _chamber decomposition_. We identified a bug in the implementation in FPL and fixed it.

The original implementation is best summarised with the following quote from FPL:

#quote(block: true, attribution: [comment in `Barvinok.cpp`])[
We maintain a list of pairwise disjoint chambers and the generating functions. We iterate over the region list. For each active region $R_j$ (corresponding to the generating function $f_j$), we examine all the current chambers $R_i$.

If $R_j$ has a full-dimensional intersection with an existing chamber $R_i$, then that chamber is replaced by two new ones:
+ the intersection $R_i inter R_j$, where the generating function is $f_i + f_j$;
+ the difference $R_i - R_j$, where the generating function is $f_i$.
]

As noted in the comment, FPL separates the chambers only when the current chamber $R_i$ and the active region $R_j$ have a full-dimensional intersection, which is justified by @LaTTE. The problem, however, is that the full-dimensionality check is performed in $bb(Z)^n$, whereas it should be performed in $bb(R)^n$.

The difference is best illustrated with an example. Consider the following 1-dimensional polyhedron $P subset.eq bb(Z)$ with two integer parameters $N$ and $M$, defined by three inequalities over $i in bb(Z)$:

$
  & 2i <= M <= 2i + 1, &#h(1em);(1)\
  & 2i >= N + 1, &#h(1em);(2) \
  & 2i + N - 2M + 2 >= 0 &#h(1em);(3) \
$

From inequalities (1) and (2), we obtain $N + 1 <= M$. From inequalities (2) and (3), we obtain $M <= N + 3/2$. Therefore, the active region of $(N, M)$ is

$
  R = {(N, M) | N + 1 <= M <= N + 3/2 }
$

The relation $R$ is full-dimensional when $M$ and $N$ are real numbers. However, since FPL deals only with integer relations, it always treats $M$ and $N$ as integers, and simplifies the active region to

$
  R_bb(Z) = {(N, M) | M = N + 1}
$

The relation $R_bb(Z)$ is not full-dimensional. Due to this mismatch, FPL discards regions that should have been considered.

The issue would be fixed if we replaced all integer-relation operations with rational-relation operations. To avoid rewriting the entire library to support rational numbers, we create an embedding from rational relations into integer relations that preserves set union, intersection, and subtraction.

To represent a rational relation $R = { bf(x) in bb(Q)^n | A bf(x) + bf(b) >= 0 }$ as an integer relation, we introduce an extra integer variable $d -> +infinity$ that is intended to be interpreted as the common denominator. The relation is then embedded as $R' = { (bf(x)', d) in bb(Z)^(n+1) | A bf(x)' + bf(b) d >= 0 }$, where $bf(x)'$ denotes $d bf(x)$.

We then perform subtraction and intersection on the relations exactly as for ordinary integer relations. The simplification that rounds rational numbers to integers affects only the constant term, rather than the coefficients $bf(b)$ of $d$.

After chamber decomposition, we obtain a list of chambers of the form
$
  S' = {(bf(x)', d) in bb(Z)^(n+1) | A bf(x)' + bf(b) d + bf(c) >= 0 }
$

To convert them back into integer relations, we note that $d -> +infinity$, so when we divide both sides by $d$, only the sign of $bf(c)_i$ matters.

For an inequality $A_(i, :) dot bf(x)' + bf(b)_i d + bf(c)_i >= 0$:

- If $bf(c)_i < 0$, it is lowered to $A_(i, :) dot bf(x) + bf(b)_i >= 1$;

- If $bf(c)_i >= 0$, it is lowered to $A_(i, :) dot bf(x) + bf(b)_i >= 0$.

=== Summation <incl-excl>

We have discussed the method for computing the list of active regions and their generating functions for a single parametric polyhedron $P = { bf(x) | A bf(x) + B bf(p) + bf(c) >= 0 }$. In our cache-miss counting analysis, however, we must count integer points inside integer relations, which can be unions of several polyhedra. We therefore need inclusion-exclusion.

Take an integer relation $union.big_(i=1)^m P_i$. For every set $cal(P) subset.eq {P_i}$, we compute the list of active chambers and generating functions $(R_cal(P), f)$ of $inter.big cal(P)$, together with parameter constraints $C_bf(p)$. The active region of the generating function $f$ is then $R = R_cal(P) inter C_bf(p)$. Since the intersection of polyhedra is also a polyhedron, it suffices to apply the methods described in the previous sections.

We rely on FPL to evaluate the generating function $f$ at $bf(x) = 1$ to obtain a quasi-polynomial $q$ over parameters $bf(p)$ that yields the integer count. We record each triple $(cal(P)_j, R_j, q_j)$, where $q_j$ is valid when $bf(p) in R_j$.

We then perform chamber decomposition on the parameter space over the list of valid parameter regions $R$. The process is similar to the Clauss-Loechner algorithm described in @chamber-decomp, but we cannot omit lower-dimensional intersections. It produces a list of chambers $C_i$ such that, for any region $R_j$, each chamber lies either entirely inside or entirely outside the region.

For each $C_i$ after decomposition, we iterate through all records $(cal(P)_j, R_j, q_j)$. Now $C_i$ is either a subset of $R_j$ or completely disjoint from it. In the former case, the integer count for the chamber is increased by $(-1)^(|cal(P)_j|+1) q_j$ according to the inclusion-exclusion principle. In the latter case, the count for the chamber is unchanged.

This completes parametric Barvinok's algorithm, which yields a list of parameter regions and an integer count function within each region.

== Optimisations <optimisations>

=== Caching Chamber Ownership <cache-ownership>

In @incl-excl, we showed that to calculate the integer count inside union of polyhedra, we need to first decompose the parameter space into chambers $C_i$, and then check whether each region $R_j$ is a superset of it.

The superset check involves an emptiness test and is expensive. We can remove the check by precomputing the result in decomposition. Instead of decomposing the universe into chambers $C_i$ only, we now compute pairs $(C_i, bf(b)_i)$ where $bf(b)_i$ is a bitvector. Here $bf(b)_(i j) = 1$ means $R_i$ is a subset of $R_j$, and $bf(b)_(i j) = 0$ means they are disjoint.

On each step of decomposition, we enumerate through active regions $R_j$ and split each chamber $C_i$ into $C' = C_i inter R_j$ and $C'' = C_i - R_j$. We know $R_j$ contributes to the former chamber but not to the latter, and hence we can set $bf(b)'_j$ to $1$ and unset $bf(b)''_j$ to $0$, while copying other entries from $bf(b)_i$ associated with $C_i$.

=== Early Removal of Empty Relations <early-removal>

In @comp-miss-count, we invoke an FPL procedure to compute lexicographical maximum of a presburger relation.

The procedure first computes a piecewise affine function for each disjunct, and then unions them into a single function. The union of two piecewise funcions is performed by enumerating all pairs of pieces $(R_i, f_i)$ and $(S_j, g_j)$. The algorithm then computes the region $T = { bf(x) | f_i(bf(x)) lexge g_j(bf(y)) }$ and then splits the regions into $R_i inter T$ and $R_i - T$. The number of pieces in the union grows exponentially to the number of disjuncts in the worst case.

We noticed, however, that most of the relations formed subtraction or intersections are in fact infeasible. By removing these regions when they appear, we prevented them from participating in the union steps and contributing to exponential behaviour. For our test cases, although the number of pieces is still exponential, it scales much slower after our optimisation (@eval-early-removal).

=== Parallelism <parallel>

As noted in @Falcon, we process each sink statement separately in our cache model, and the process is read-only. The model is hence embarassingly parallel, and we can exploit the parallelism to obtain a 3.9x speedup, as shown in @eval-parallel.
