#import "@preview/cuti:0.4.0"
#import "heb.typ": heb, heb-sheet, ltr-island, large-arrow

#set document(title: "希伯来语学习笔记 (2)")
#set page(paper: "a4", margin: 2.3cm)
#set text(size: 10.5pt, font: ("Libertinus Serif", "Noto Serif CJK SC", "SBL Hebrew"))
#set heading(numbering: "1.1")
#show link: underline
#show text.where(lang: "he"): set text(font: ("SBL Hebrew", "Noto Serif Hebrew", "DejaVu Serif"))

= 作为连词的 #heb("w")

在上一篇文章中，我们已经观察到了 #heb("w:") 表示“和”的意思。不过，这个东西本身也会变形。

对于普通的单词，它就正常地以 #heb("w:") 的形态贴在前面：

#heb("w:semeN") #large-arrow #heb("semeN") [油] \
#heb("w:leHeM") #large-arrow #heb("leHeM") [面包] \
#heb("w:`eVed") #large-arrow #heb("`eVed") [奴隶]

如果词语以加了 #heb("d.AgEs")（强调点）的 #heb("bgdkft") 字母开头，它会消失。这是因为它前面变成了开音节，而开音节之后的强调点会默认为重强调点。我们不想这样，所以只好去掉它了。这个脱落现象在其他地方也会出现，比如上一个词以元音结尾时，下一个词开头的强调点可能会脱落，但并非所有地方都是如此。

#heb("w:beSeF") #large-arrow #heb("b.eSeF") [银子/钱]

== 特例：变音

如果词语以双唇音 #heb("b.p.m") 开头，那么 #heb("w:") 会变为 #heb("w.")。希伯来语中，这是词语以元音开头唯一的可能性。

#heb("w.p:riy") #large-arrow #heb("p.:riy") [水果] \
#heb("w.VAs,Ar") #large-arrow #heb("VA.s,Ar") [肉] \
#heb("w.mayiM") #large-arrow #heb("m.ayim") [水]

如果词语以发音的 schwa 开头，那么 #heb("w:") 也会发生同样的变化。

#heb("w.d:Vas") #large-arrow #heb("d:.Vas") [蜂蜜] \
#heb("w.s:lOmOh") #large-arrow #heb("s:lOmOh") [所罗门] \
#heb("w.r:HOV") #large-arrow #heb("r:HOV") [城中广场]

不过，特别的是，如果是 #heb("y:") 开头的，那么 #heb("w:y:") 会整体变为 #heb("wiy")。

#heb("wiylw.sAlami") #large-arrow #heb("y:lw.sAlami") [耶路撒冷]

如果词语以最短的那一系列元音开头，#heb("w:") 的 schwa 会被同化。这样的词一般都以 #heb("'`hH") 之一开头。

#heb("wa'a:niy") #large-arrow #heb("'a:niy") [我] \
#heb("we'em:et") #large-arrow #heb("'e:met") [真实] \
#heb("wo'o:niy.Ah") #large-arrow #heb("'o:niy.Ah") [船]

== 特例：神名

对于神的名称 #heb("yhwh")，由于古代的宗教禁忌，人们不会直接发音（所以现代人也不知道如何发音）。一般遇到这个词会读作 #heb("'a:dOnay")，而给 #heb("yhwh") 标点时，会写作 #heb("y:hvAh")。它是特别的：

#heb("wayhwAh") #large-arrow #heb("y:hvAh") [上帝]

还有一个表示神的词也是特别的，会把前面的 #heb("'e:") 和 #heb("w:") 一起合并为 #heb("vE'")。和前面提到的同化不一样的是，这里的 #heb("'") 下的标点消失了，而 #heb("v") 的标点则从 #heb("we") 变为了 #heb("wE")。

#heb("vE'lOhiyM") #large-arrow #heb("'e:lOhiyM") [神]

== 特例：并举

当两个词有很强的并列、对举意味的时候，倾向于使用 #heb("wA")，不过不是强制性的。

#heb("leHeM wAmayiM") [面包和水] \
#heb("zAHAV wAbeSeF") [金和银]

注意这时强调点仍然会消失。

== 连接句子

除了作为“和”以外，#heb("w:") 还可以连接两个句子，起“而”的作用。可以顺承、转折等等，跟古代汉语的“而”是比较相似的。

#heb("ham.eleK: yOsEV b.:twOK: hEykAl gA.dwON va'a:niy yOsEV b:.twOK: s,Adeh qATOF")

这里的 #heb("va'a:niy") 就是“（国王坐在大王座上，）*而*我（却坐在小田野里）”，表示转折。

= 介词

== 独立介词

顾名思义，独立介词就是一个单独的词，比如上一篇文章中的 #heb("'Ecel") [在…旁]。

#heb("ham.eleK: yOsEV 'Ecel hasu.l:HAN")

== 可分介词

这种介词可以独立存在，也可以通过希伯来语的连字符 #heb("-") 连接到词上。例如上一篇文章中的 #heb("`al-") 就是这样的。比如：

#heb("`al-has.ul:HAN") [on: 在桌子上] \
#heb("'el-hahEykAr") [to: 向宫殿] \
#heb("`iM-haS.w.S") 或者 #heb("'et-haS.w.S") [with: 和马一起] \
#heb("miN-hahEykAl") [from: 从宫殿里] \
#heb("`ad-ham.is:t.eh") [until: 直到宴会]

以 #heb("'e") 开头的两个介词在独立形态的时候，会改为以 #heb("'E") 开头：#heb("'Et") [with] 以及 #heb("'El") [to]。

#heb("miN") 的这个 #heb("n") 可能会被同化。这时，介词作为 #heb("mi") 前缀直接粘在词首，而原本的词首辅音将会双写。

#heb("miS.w.S") #large-arrow #heb("miN-Sw.S")

既然要双写，就必须考虑无法双写的喉音。和 #heb("ha") 在喉音前拉长为 #heb("hA") 一样，#heb("mi") 将会变长为 #heb("mE")。这是因为 e, i 是同一族元音，而 o, u 是另一族。

#heb("mEHAkAM") #large-arrow #heb("miN-HAkAM") [从智者]

== 不可分介词

这些介词无法独立存在。比较常见的有三个：#heb("b.:") [in, at; with, by], #heb("k.:") [like, as], #heb("l:") [to, for]。

它们和 #heb("v:") 的规则类似。没有双唇音的规则，但发音 schwa 的规则是存在的。#heb("v:") 变为 #heb("v.")，但这里三个介词都会将元音变为短 i：

#heb("b.id:Vas") #large-arrow #heb("d:Vas") [in: 在蜂蜜里] \
#heb("k.is,:lOmOh") #large-arrow #heb("s,:lOmOh") [like: 像所罗门一样] \
#heb("lid:.HwOV") #large-arrow  #heb("d:.HwOV") [to: 向城中广场]

对于 #heb("y:") 开头的词，和 #heb("v:") 变为 #heb("viy") 一样，它们也会消除 #heb("y") 的 schwa，然后本身变为短 i：

#heb("b.iyrw.sAlaMi") #large-arrow #heb("y:rw.sAlaMi") [in: 在耶路撒冷中]

它们也会跟 #heb("w:") 发生短元音同化，这里就不举例了。

== 定冠词缩合

不可分介词会与 #heb("ha") 缩合。它们会替代定冠词的辅音 #heb("h")，留下原本的元音。

#heb("b.ahEykAl") #large-arrow #heb("hahEykAl") [在这个宫殿里] \
#heb("k.A'.iys") #large-arrow #heb("hA'iys") [像这个男人一样]

= 例文

#heb("ham.is:t.eh")

#heb("vay:hiy mis:t.eh gA.dwOl b.ahEykal:: vay:hiy `al-has.ul:HAN leHeM v.bAs,Ar w:semeN w.d:Vas w.p:riy w:ham.eleK: yOsEV 'Ecel has.ul:HAN:: vay.O'mer ham.eleK: 'ay.Eh hay.ayiN v:hamayiM:: vay.AVO' `eVed 'el-hahEykAl `iM-haS.w.S vay:hiy `al-haS.w.S yayiN w:mayiM:: vay.AVO' haS.w.S 'el-has.ul:HAN v:hin.Eh haS.w.S 'OVEl leHeM w.bAs,Ar w.d:Vas w.f:riy w:haS.w.S s,AmEHa m:'Od:: vay.O'mer ham.eleK: 'ay.Eh hac.edeq 'a:niy rA`EV w:hA'Okel b.:twOK: haS.w.S")

== 练习

#heb("vay:hiy hEykAl b.iyrw.sAlaMi:: vay:hiy b.ahEykAl mis:t.eh gAdwOl:: vay:hiy b.am.is:t.eh meleK: viylAdiyM w:`eVed:: vay:hiy f:riy b.id:Vas lay:lAdiyM:: vay:hiy bAs,Ar b.:semeN w.f:riy b.:yayiN lam.eleK:_{200C}:: vay:hiy leHeM b.:mayiM lA`eVed:: vay.O'mer hA`eVed b.e'e:met 'EyN cedeq b.A'AreC")

注意 #heb("'ereC") 的定冠词形态是 #heb("h.A'Arec")，这是不规则的。上一篇文章也提到了这一点。

还有一个翻译小练习。

The king is in the palace. The king is sitting on the throne. The throne is next to the table. The table is empty. Where is the food? The servant is in the garden. On the earth next to the servant is meat and bread and oil and fruit and honey and wine. The servant is very happy. The king is very hungry.

#heb("ham.eleK: b.ahEykAl:: hame.leK: yOsEV `al-hak.iSE':: haki.SE' 'Ecel has.ul:HaN:: has.ul:HAN rEyq:: 'ay.Eh hA'Okel:: hA`eVed b.agAN:: `al-`ereC 'Ecel hA'eVed b.As,Ar v:leHeM w:semeN w.f:riy w.d:Vas v:yayiN:: hA`eVed s,AmEHa m:'Od:: ham.eleK: rA`EV m:'Od")
