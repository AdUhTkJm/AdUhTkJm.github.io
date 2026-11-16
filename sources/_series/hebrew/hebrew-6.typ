#import "@preview/cuti:0.4.0"
#import "heb.typ": heb, heb-sheet, ltr-island, to

#set document(title: "希伯来语学习笔记 (6)")
#set page(paper: "a4", margin: 2.3cm)
#set text(size: 10.5pt, font: ("Libertinus Serif", "Noto Serif CJK SC", "SBL Hebrew"))
#set heading(numbering: "1.1")
#show link: underline
#show text.where(lang: "he"): set text(font: ("SBL Hebrew", "Noto Serif Hebrew", "DejaVu Serif"))

接下来的语音变换是 _qal wayyiqtol_，区别在于前面加上了一个 #heb("wa^._-")。剩下的部分和 _yiqtol_ 是一样的。

不过，未完成体的第一人称单数形态是以 #heb("'") 开头的，它无法加强调点。所以 #heb("wa") 会强制延长为 #heb("wA")。

具体而言，阳性的变化是：

#table(columns: 3, stroke: none, align: right,
[], [*单数*], [*复数*],
[第一人称], [#heb("wA'eq:TOl")], [#heb("wan.iq:TOl")],
[第二人称], [#heb("wat.iq:TOl")], [#heb("wat.iq:T:lw.")],
[第三人称], [#heb("way.iq:Tol")], [#heb("way.iq:T:lw.")],
)

阴性形式：

#table(columns: 3, stroke: none, align: right,
[], [*单数*], [*复数*],
[第一人称], [#heb("wA'eq:TOl")], [#heb("wan.iq:TOl")],
[第二人称], [#heb("wat.iq:T:liy")], [#heb("wat.iq:TO<l:nAh")],
[第三人称], [#heb("wat.iq:Tol")], [#heb("wat.iq:TO<l:nAh")],
)

这个形态主要用于叙事的主线，而主线之外的部分则使用 _qatal_ 或者 _yiqtol_。

= 例文

#heb("hA`Ez")

#heb("vay:hiy 'aha:rEy ham.is:t.eh vay.is:r:fw. ham.:lAkiyM v:ham.:lAkwOt 'et-ha`iyr b.A'Es vay.il:k.:dw. 'et-hahEykAl vay.im:l:kw. bA'AreC vay.ik:r:Hw. ham.eleK: v:hamal:k.Ah 'el-has,Adeh yAs:Vw. 'et-haS.w.s 'et-hag.:mal.iyM 'et-hA'a:twOnwOt:: vay.ar:' hame.leK: v:hin.Eh `:z b.:twOK: has,Adeh v:hA`Ez 'Ok:lAh 'et-hak.EliyM 'a:ser 'Ak:dw.:: vay.if:qOd ham.eleK: 'et-hahEykAl vay.O'mer 'et-ham.:lAkiyM v:'et-ham.:lAkwOt `at.Ah yAda`:t.iy kiy lO' g:nab:t.eM 'et-hak.eliyM k.iy `Ez 'Ak:lAh 'OtAM:: vay.iS:l:Hw. lam.eleK: vay.ik:r:tw. b:.riyt vay:hiy sAlwOM b:kol-hA'a:rAcwOt")

== 词表

#heb("'aHa:rEy") 在…之后 [介词]

#heb("brH") 逃跑

#heb("r'h") 看

#heb("`ez") 山羊 [f]；复数 #heb("`iz.iyM")

#heb("'kd") 消失；死亡

#heb("fqd") 拜访

#heb("SlH") 原谅；支配介词 #heb("l:")

#heb("krt") 切开。在这里，#heb("krt b:.riyt") 意为“缔结盟约”。

#heb("'OtAM") 它们（宾格）

== 注

这里的 #heb("yAs:Vw. 'et-haS.w.S") 处的 #heb("'et-") 是介词 with，而不是宾格标记。

#heb("r'h") 在变形的时候，第三个辅音 #heb("h") 脱落了。它本应是 \*#heb("way.ar:'eh")（这里的 #heb("'e") 也是第三个辅音是 #heb("h") 导致的特殊未完成体形态，本应根据喉音的规则变为 #heb("'a")），实际上却只剩下 #heb("way.ar")。感觉教材后面应该会提到具体的变化规则。

这里的 #heb("'Ok:lAh") 确实来自 #heb("'kl") “吃”，但这里是主动分词形式。

== 练习

为这段希伯来语标点，并在合适的情况下，将 _qatal_ 形式的词语换成 _wayyiqtol_ 形态。

#heb("vyhy 'Hry hmlHmh gnbh hsfHh 't-kl-hkSF 'sr bhykl gnb h`bd 't-kl-hzhb brHv h`bd whsfHh mN-hhykl 't-hkSF v't-hzhV 'mr hmlK 'vy ly ky `z 'klh 't-hklyM vh`Vd vhsfHh gnbv 't-hkSF v't-hzhb")

转换后的结果是：

#heb("vay:hiy 'aHa:rEy hami.l:HAmAh wat.ig:nOb has.if:HAh 'et-kol-hak.eSeF 'a:ser ba.hEykAl way.ig:nOb hA`eVed 'et-kol-haz.AhAV:: vay.ib:r:Hw. hA`eVed v:has.if:Hah miN-hAhEykAl 'et-hak.eSeF v:'et-haz.AhAV:: vay.O'mer ham.eleK: 'wOy-liy kiy `Ez 'Ak:lAh 'et-hak.EliyM v:hA`eVed v:has.if:HAh gAn:bw. 'et-hak.eSeF v:'et-haz.AhAV")

*词表*

#heb("k.eSeF") 钱；银子

#heb("zAhAV") 金子
