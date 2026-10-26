#import "@preview/physica:0.9.8": *

#set document(title: "量子计算笔记 (1)")
#set page(paper: "a4", margin: 2.3cm)
#set text(size: 10.5pt, font: ("Libertinus Serif", "Noto Serif CJK SC"))
#set heading(numbering: "1.1")
#show link: underline

#let Tr = "Tr"

= 简介

我最近在上量子复杂度理论这门课。虽然去年学过量子计算，但这门课似乎又引入了一堆新东西，而且特别数学。

我的线性代数好不到哪里去，所以不得不把它整理一下记下来。

== 量子状态

量子态分为*纯态*和*混合态*。纯态就是量子态的叠加：

$ ket(phi) = sum_i ket(b_i) $

而混合态则是纯态的概率分布：

$ rho = sum_i lambda_i ketbra(phi_i, phi_i) $

其中 $sum lambda_i = 1$。

在之前学过的量子计算里，我们能看到的东西都是纯态。那么，为什么要发明混合态呢？

考虑 Bell 态 $1/sqrt(2) (ket(00) + ket(11))$。它的第一个量子比特就可以用混合态表示：

$ rho_1 = 1/2 ketbra(0) + 1/2 ketbra(1) $

所以，复合系统的局部状态可能是混合态。

需要注意的是，这里的混合态定义是 $ket(phi)$ 投影矩阵的叠加。如果直接写作 $sum lambda_i ket(phi_i)$，一方面是无法保证归一化，另一方面是这只不过是纯态的线性组合，还是纯态。所以，混合态是*矩阵*，不能用 $ket(dot)$ 记号表示。

== 谱定理

*谱定理* (_spectrum theorem_) 说的是，如果 $A$ 是 Hermitian 矩阵，那么它一定可以写成

$ A = sum_i lambda_i ketbra(b_i) $

其中 $lambda_i$ 是 $A$ 的特征值，而且一定是实数；$ket(b_i)$ 是正交归一的一组基。所以，我们可以将 Hermitian 矩阵某种程度上看作是实数向量。

== 密度矩阵

如果 Hermitian 矩阵 $rho$ 是半正定的（所有特征值非负），而且 $Tr(rho) = 1$，那么 $rho$ 就是*密度矩阵*。

线性代数的知识正在攻击我。实际上，虽然 $Tr$ 的定义是主对角线之和，但是它等于特征值之和。这是因为 $A$ 的特征多项式 $det(lambda I - A)$ 的所有零点自然是 $lambda_i$；而直接展开的话，又会发现 $det(lambda I - A)$ 的 $lambda^(n-1)$ 一项系数等于 $-sum a_(i i)$。那么根据韦达定理，自然有

$
  sum_i a_(i i) = sum_i lambda_i
$

所以，既然要求特征值非负，而且和为 1，我们就可以将密度矩阵看作是它的正交基上的概率分布。这里 Hermitian 矩阵的作用正是为了确认基是正交的，这就是我们最开始要引入谱定理的原因。

密度矩阵描述了一个量子态的所有物理信息。不过，它无法描述量子态的制备历史，因为两种不同的制备方式可能会获得同一个密度矩阵。考虑

$ 1/2 ketbra(0) + 1/2 ketbra(1) = 1/2 mat(1, 0; 0, 1) + 1/2 mat(0, 1; 1, 0) = 1/2 mat(1, 1; 1, 1) $

$ 1/2 ketbra(+) + 1/2 ketbra(-) = 1/4 mat(1, 1; 1, 1) + 1/4 mat(1, 1; 1, 1) = 1/2 mat(1, 1; 1, 1) $

所以通过半 $ket(0)$ 半 $ket(1)$，和通过半 $ket(+)$ 半 $ket(-)$ 制备出来的量子态其实是一模一样的。这种恰好等于 $I / 2$ 的混合态称为*最大混合态* (_maximally mixed state_)，因为它的本征值是均匀的，每一个都是 $1/2$。对于 $n$ 维的混合态，最大混合态自然是 $I/n$。

在 $ket(0), ket(1)$ 这组基下，密度矩阵的非对角项表示*相干* (_coherence_)。考虑

$ rho = mat(rho_(00), rho_(01); rho_(10), rho_(11)) $

那么 $rho_(i j)$ 其实是等于 $braket(i, rho, j)$ 的。那么非对角元素 $rho_(i j)$ 自然表示了 $ket(i)$ 和 $ket(j)$ 有多大的关系。实际上，要看相不相干还是得看 $braket(i, rho, j)$，只是恰好这里可以直接通过那几个元素读出来而已。

如果非对角元是 0，那么在这个基下 $rho$ 是无相干的。最大混合态在任何基下都无相干。

== 投影测量

投影测量 (_projective measurements_) 一般简称 PVM，由一组矩阵 ${M_i} (1 <= i <= k)$ 确定，其中每个 $M_i$ 都是 Hermitian 的，而且要求 $M_i$ 是幂等的 ($M_i^2 = M_i$)。$M_i$ 是个投影，一定不可逆。我当时在这里纠结了半天，认为这个条件加上 $M_i = M_i^dagger$ 必然有 $M_i = I$，才发现 $M_i^(-1)$ 不见得存在。

我们还要求 $sum M_i = I$，才将这样一组 $M_i$ 称作 PVM。

既然是测量，我们可以用这些 $M_i$ 去测量一个纯态 $ket(psi)$，得到 $k$ 种不同的结果。结果 $i$ 的概率是

$ ||M_i ket(psi)||^2 = braket(psi, M_i^dagger M_i, psi) = braket(psi, M_i, psi) $

测量后，状态的方向坍缩到了 $M_i ket(psi)$。还需要叠加一个归一化，除以 $||M_i ket(psi)||$ 才行。

注意到，$||M_i ket(psi)||^2$ 其实等于 $Tr(M_i ketbra(psi))$。这是因为 $Tr(A B C) = Tr(B C A)$，从而

$ Tr(M_i ketbra(psi)) = Tr(braket(psi, M, psi)) = braket(psi, M, psi) $

最后一步是因为那个值就是个实数，而实数的 Tr 自然是它本身。

注意到纯态 $ket(psi)$ 写作混合态时，其实是 $rho = ketbra(psi)$，而 $ketbra(psi)$ 又在 PVM 里出现了一次。那么直觉告诉我们，对任意的混合态 $rho$，用 ${M_i}$ 测量后概率理应也是 $Tr(M_i rho)$。

在测量出结果 $i$ 之后的坍缩则是

$ (M_i rho M_i) / (Tr(M_i rho)) $。

要理解这个，我们还是先看纯态是怎么样的。对于 $ket(psi)$，它坍缩到 $M_i ket(psi)$。写成混合态的话，就是对于 $ketbra(psi)$，它坍缩后的分子是 $(M_i ket(psi)) (M_i ket(psi))^dagger$，而这恰好是 $M_i ketbra(psi) M_i$（毕竟 $M_i$ 是 Hermitian 的）。所以，如果推广到混合态 $rho$，分子就是 $M_i rho M_i$ 了。分母自然来自归一化，和纯态的也是一样的。

== 偏迹与纯化

我们最开始讲了混合态其实可以用来描绘复杂系统的局部。那么，我们该如何将它提取出来呢？

考虑一个 $A$, $B$ 一起构成的量子系统，它的密度矩阵记作 $rho_(A B)$。那么如果 $A$ 的密度矩阵位于 $cal(H)_A$ 中，$B$ 的密度矩阵位于 $cal(H)_B$ 中，这个复合系统的矩阵自然需要在 $cal(H)_A times.o cal(H)_B$ 内。

而偏迹 $rho_A = Tr_B (rho_(A B))$ 指的是将 $rho_(A B)$ 按 $B$ 分块后，这个分块矩阵的主对角线之和。以二维为例，$rho_(A B)$ 是一个 $4 times 4 $ 的矩阵，不过按照 $B$ 分块之后就只剩下 $2 times 2$ 了：

$ rho_(A B) = mat(B_(0 0), B_(0 1); B_(1 0), B_(1 1)) $

那么 $Tr_B (rho_(A B))$ 就是 $B_(0 0) + B_(0 1)$，依然是一个矩阵，而且刚好和 $A$ 的普通密度矩阵大小相同。形式化地说，

$ Tr_B (ketbra(a_1 b_1, a_2 b_2)) = ketbra(a_1, a_2) braket(b_1, b_2) $

如果 $a_n$ 和 $b_n$ 都是正交归一的，就只留下 $Tr_B (ketbra(a_n b_m, a_n b_m)) = ketbra(a_n, a_n)$，剩下的都是零。

系统 $A$ 的每一个混合态都可以找到某个 $rho_B$，使得它们拼起来是一个纯态。这就叫作*纯化*：

$ forall rho_A." " exists ket(psi)_(A B)." " rho_A = Tr_B (ket(psi)_(A B)) $

而且，Uhlmann 定理告诉我们，所有这样的 $ket(psi)$ 都可以通过某个 unitary 矩阵相互转化。这里 unitary 是指 $U^(-1) = U^dagger$，而 Hermitian 则是说 $H = H^dagger$。

== 迹距离

两个量子态的距离 $D(rho, sigma)$ 定义为

$ D(rho, sigma) = 1/2 Tr |rho - sigma| $

它确定了两个量子态通过测量被区分的最大概率，这个值是 $(1 - D(rho, sigma)) / 2$。

== 量子信道

我们描述了很多量子操作，包括直接乘以某个 unitary 矩阵 $U$，进行测量，以及补上/消去系统的一部分 $B$ 之类的。它们是否能统一描述呢？

实际上，所有这些都对应一种 CPTP 映射 (_completely positive trace-preserving_)。对于一个映射 $cal(S)$，如果它要是 CPTP，那么就必须满足这些条件：

- *正性*。对任意的混合态 $rho >= 0$，必定有 $cal(S)(rho) >= 0$；
- *完全正性*。如果它作用于某个更大系统的一部分，也需要保持正性。也就是说，对任意的系统 $B$，以及总状态 $sigma >= 0$，那么 $(I times.o cal(S))(sigma) >= 0$。
- *保迹*。既然密度矩阵表示概率，那么 $Tr = 1$ 的条件不能改变。所以要求 $Tr rho = Tr cal(S)(rho)$。

Kraus 表示告诉我们，这样的 $cal(S)$ 总是可以写作 $sum_k A_k rho A_k^dagger$，其中 $A_k$ 是任意矩阵。为了能够保迹，$A_k A_k^dagger$ 之和需要等于 $I$。
