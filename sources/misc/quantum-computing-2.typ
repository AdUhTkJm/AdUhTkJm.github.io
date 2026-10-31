#import "@preview/physica:0.9.8": *

#set document(title: "量子计算笔记 (2)")
#set page(paper: "a4", margin: 2.3cm)
#set text(size: 10.5pt, font: ("Libertinus Serif", "Noto Serif CJK SC"))
#set heading(numbering: "1.1")
#show link: underline

#let Tr = "Tr"
#set enum(numbering: "(a)")

这次是做题环节。

似乎 MathML 对矩阵之类的支持挺不好的，所以为了阅读体验，建议去看 PDF 版本，按钮就在上面（藏得比较深）。

= 密度矩阵，谱定理

对于 $t in RR$，令 $rho_t = display(1/2 mat(1, t; t, 1))$。

+ 计算 $rho_t$ 的特征值和正交归一的特征基。要让 $rho_t$ 是密度矩阵，$t$ 的可能取值有哪些？
  
  *解.* $det(lambda I - rho_t) = 0$，也就是 $display(mat(1-2lambda, t; t, 1-2lambda, delim: "|") = 0)$。那么，$display(lambda = 1/2 (1 plus.minus t))$。

  至于特征向量，
  $ mat(1 - 2 lambda, t; t, 1 - 2 lambda) vec(a, b) = bold(0) $

  $display(lambda = 1/2 (1+t))$ 时，特征向量为 $vec(1, 1)$；$display(lambda = 1/2 (1-t))$ 时，则为 $vec(1, -1)$。我们需要正交归一的基，那么除以 $sqrt(2)$ 就可以了。

  要让 $rho_t$ 是密度矩阵，只需要让它是 Hermitian 的半正定矩阵，而且 $Tr rho_t = 1$ 即可。只有半正定会对 $t$ 有约束，也就是 $1/2 (1 plus.minus t) >= 0$，那么 $-1 <= t <= 1$。

+ 将 $rho_t$ 写作两个纯态的加权和。

  *解.* 容易想到这两个纯态就是 $ket(v_1) = display(1/sqrt(2) vec(1, 1))$ 和 $ket(v_2) = display(1/sqrt(2) vec(1, -1))$。所以，

  $ rho_t = 1/2 ketbra(v_1) + 1/2 ketbra(v_2) $

+ 证明当且仅当 $Tr(rho^2) = 1$ 的时候，$rho$ 是纯态。

  *解.* 假设 $Tr(rho^2) = 1$。令 $rho = display(mat(a, b; b^*, 1-a))$，那么

  $ rho^2 = mat(a^2+||b||^2, b; b^*, (1-a)^2 + ||b||^2) $

  所以 $Tr(rho^2) = a^2+(1-a)^2+2||b||^2 = 1$，这说明 $a = a^2 + ||b||^2$。

  要让 $rho$ 是纯态，就必须找到 $ket(psi) = display(vec(x, y))$ 使得 $rho = ketbra(psi)$，也就是

  $ mat(a, b; b^*, 1-a) = mat(||x||^2, x y^*; x^* y, ||y||^2) $

  显然 $||x||, ||y||$ 已经被 $a$ 所确定。为了让它有解，我们只需要让 $b b^* = a (1 - a)$ 即可，而 $a = a^2 + ||b||^2$ 已经说明了这一点。

  再假设 $rho = ketbra(psi)$ 是纯态。那么只要计算一下，就可以得知 $Tr(rho^2) = 1$，过程和上面的基本上完全一样。

= 相干

令 $ket(psi_(plus.minus)) = display(1/2 (sqrt(3) ket(0) plus.minus ket(1)))$，$tau = display(3/4 ketbra(0) + 1/4 ketbra(1))$。

+ 计算 $ket(psi_+)$, $ket(psi_-)$ 等比例混合所得到的混合态。它可以与 $tau$ 区分吗？

  *解.* $
  rho &= 1/2 ketbra(psi_+) + 1/2 ketbra(psi_-) \
      &= 1/8 mat(3, sqrt(3); sqrt(3), 1) + 1/8 mat(3, -sqrt(3); -sqrt(3), 1) \
      &= 1/4 mat(3, 0; 0, 1) = tau 
  $

  既然密度矩阵相同，它们是不可区分的。

+ 计算 computational basis 下，$ketbra(psi_+)$ 和 $tau$ 的测量结果分布。

  *解.* 对于 $tau$，它自然是 $3/4$ 得到 $ket(0)$，$1/4$ 得到 $ket(1)$。

  对于 $ketbra(psi_+)$，它等于 $display(1/4 mat(3, sqrt(3); sqrt(3), 1))$，所以同样也是 $3/4$ 得到 $ket(0)$，$1/4$ 得到 $ket(1)$。

+ 计算 $H tau H^dagger$，并由此得到 $ketbra(psi_+)$ 和 $tau$ 在 Hadamard 基下的测量结果分布。

  *解.* $
    H tau H^dagger
    &= 1/8 mat(1, 1; 1, -1) mat(3, 0; 0, 1) mat(1, 1; 1, -1) \
    &= 1/8 mat(1, 1; 1, -1) mat(3, 3; 1, -1) \
    &= 1/8 mat(4, 2; 2, 4) \
    &= 1/4 mat(2, 1; 1, 2)
  $

  这说明 $tau$ 在 $H$-基下有 $1/2$ 概率得到 $ket(+)$，$1/2$ 概率得到 $ket(-)$。

  再考虑 $ketbra(psi_+)$。
  
  $ H ket(psi_+) = 1/(2 sqrt(2)) mat(1, 1; 1, -1) vec(sqrt(3), 1) = 1/(2 sqrt(2)) vec(sqrt(3) + 1, sqrt(3) - 1) $

  所以 $
  H ketbra(psi_+) H^dagger
  &= 1/8 vec(sqrt(3) + 1, sqrt(3) - 1) (sqrt(3) + 1, sqrt(3) - 1) \
  &= 1/8 mat(4 + 2 sqrt(3), 2; 2, 4 - 2 sqrt(3))
  $

  因此得到 $ket(+)$, $ket(-)$ 的概率分别是 $display((4 + 2sqrt(3)) / 8)$ 以及$display((4 - 2sqrt(3)) / 8)$。

= PVM

两个量子比特以 $rho = ketbra(++)$ 形式被制备出来。考虑

$ M_"even" = ketbra(00) + ketbra(11), M_"odd" = ketbra(01) + ketbra(10) $

+ 证明 $M_"even", M_"odd"$ 是一组投影测量矩阵。

  *解.* 首先，它们加起来是 I。

  然后，$M_"even"$ 和 $M_"odd"$ 都是 Hermitian 的，而且都幂等。所以，它们构成一组投影测量矩阵。

+ 计算测量的可能结果以及坍缩后的密度矩阵。它是否是纠缠态？

  *解.* 首先看 $M_"even"$。我们有

  $
  M_"even" rho
  &= 1/4 mat(1, 0, 0, 0; 0, 0, 0, 0; 0, 0, 0, 0; 0, 0, 0, 1) mat(1, 1, 1, 1; 1, 1, 1, 1; 1, 1, 1, 1; 1, 1, 1, 1) \
  &= 1/4 mat(1, 1, 1, 1; 0, 0, 0, 0; 0, 0, 0, 0; 1, 1, 1, 1) $

  所以概率为 $Tr(M_"even" rho) = 1/2$。测量后的状态是 $M_"even" rho M_"even"$ 除以归一化系数，所以是

  $ rho' = 1/2 mat(1, 0, 0, 1; 0, 0, 0, 0; 0, 0, 0, 0; 1, 0, 0, 1) $

  $M_"odd"$ 也是类似的，只不过换了一下顺序而已。

  这个东西确实是纠缠态，毕竟不可能存在 $a times.o b$ 使得它等于 $rho'$。

+ 如果分别对每个比特在 computational basis 下测量，结果又会如何呢？

  *解.* 这会是 $ket(01), ket(10), ket(00), ket(11)$ 中的某一种，概率各为 $1/4$。所以，一个非对角项都没有留下来。

= 纯化

令 $ket(Psi_(A B)) = display(1/2 (sqrt(3) ket(00) + ket(11)))$。

+ 计算 $rho_A = Tr_B ketbra(Psi)$ 和 $rho_B = Tr_A ketbra(Psi)$。它们是否是纯态？

  *解.* 写成矩阵形式的话，

  $ ket(Psi) = 1/2 vec(sqrt(3), 0, 0, 1) $

  所以

  $ rho_Psi = 1/4 mat(3, 0, 0, sqrt(3); 0, 0, 0, 0; 0, 0, 0, 0; sqrt(3), 0, 0, 1) $

  那么，对于 $A$ 来说，我们可以将它看作是分块矩阵：
  
  $ rho_(Psi_(A B)) = mat(A_(0 0), A_(01); A_(10), A_(11)) $

  这样分块，是因为 $A$ 的指标相同。前两个是 $ket(00), ket(01)$，$A$ 都是零；后两个是 $ket(10), ket(11)$，$A$ 都是 1。

  所以 $rho_B = Tr_A ketbra(Psi)$ 是 $A_(00) + A_(11)$，它等于 $display(1/4 mat(3, 0; 0, 1))$。

  对于 $B$ 而言，需要稍微交换一下才能把属于它的部分放在一起。我们需要按照 $B$ 指标相同来分块，而 1、3 列的 $B$ 指标相同（均为零），2、4 列也是（均为 1），所以重新排列之后相当于把 2、3 列交换。同理，2、3 行也需要交换。不过所有这些都全为零，所以其实没变：

  $ rho_(Psi_(B A)) = 1/4 mat(3, 0, 0, sqrt(3); 0, 0, 0, 0; 0, 0, 0, 0; sqrt(3), 0, 0, 1) $

  那么同样分块之后对主对角线求和，就可以知道 $rho_A = Tr_B ketbra(Psi) = display(1/4 mat(3, 0; 0, 1))$ 了。

  下面我们要检查这是不是纯态。如果它等于某个 $ketbra(psi)$，那么令 $psi = display(vec(a, b))$，就有

  $ 1/4 mat(3, 0; 0, 1) = mat(||a||^2, a b^*; a^* b, ||b||^2) $

  解得 $a = display(sqrt(3)/2)$, $b = display(1/2)$。所以这确实是纯态。

+ 说明 $ket(Psi') = display(1/2 (sqrt(3) ket(0+) + ket(1-)))$ 也是 $rho_A$ 的纯化，并找到一个作用在 $B$ 上的 $U$，将 $Psi$ 转化为 $Psi'$。

  *解.* 显然这个 $U = H$。

  $Psi'$ 显然是纯态。要说明 $Psi'$ 是 $rho_A$ 的纯化，我们需要先将这个矩阵写出来。它等于

  $ ket(Psi') = 1/(2sqrt(2)) vec(sqrt(3), sqrt(3), 1, -1) $

  所以

  $ ketbra(Psi') = 1/8 mat(3, 3, sqrt(3), -sqrt(3); 3, 3, sqrt(3), -sqrt(3); sqrt(3), sqrt(3), 1, -1; -sqrt(3), -sqrt(3), -1, 1) $

  要考虑 $rho_A = Tr_B ketbra(Psi')$，我们就需要按照 $B$ 的指标重新排列。

  $ rho_(Psi'_(B A)) = 1/8 mat(3, sqrt(3), 3, -sqrt(3); sqrt(3), 1, sqrt(3), -1; 3, sqrt(3), 3, -sqrt(3); -sqrt(3), -1, -sqrt(3), 1) $

  最后加起来：

  $ Tr_B ketbra(Psi') = 1/8 (mat(3, sqrt(3); sqrt(3), 1) + mat(3, -sqrt(3); -sqrt(3), 1)) = 1/4 mat(3, 0; 0, 1) $

  所以 $Psi'$ 也是 $rho_A$ 的纯化。

= 迹距离

+ 令 $p = diag(p_1, ..., p_d)$ 和 $q = diag(q_1, ... ,q_d)$ 为密度矩阵。证明

  $ D(p, q) = 1/2 sum_(i=1)^d ||p_i - q_i|| $

  *解.* 根据定义，$D(p, q) = display(1/2 ||p-q||_1)$。这里的 $||a||_1$ 就是特征值的绝对值之和。对于 $p - q$，它的特征值自然是 $p_i - q_i$，所以即可证明。

+ 令 $rho = ketbra(0), sigma = ketbra(+)$。计算 $rho - sigma$ 的特征值，迹距离和最大区分概率。

  *解.* 直接展开，
  
  $ rho - sigma = mat(1, 0; 0, 0) - 1/2 mat(1, 1; 1, 1) = 1/2 mat(1, -1; -1, -1) $

  要计算特征值，就需要解方程

  $ det(2(rho - sigma) - 2lambda I) = 4 lambda^2 - 2 = 0 $

  所以 $lambda = display(plus.minus 1/sqrt(2))$。那么，迹距离就是 $display(1/sqrt(2))$（别忘了除以 2），最大区分概率则为 $display((2 + sqrt(2)) / 4)$。

