#import "@preview/cuti:0.4.0"
#import "heb.typ": heb, heb-sheet, ltr-island, to

#set document(title: "希伯来语学习笔记 (9)")
#set page(paper: "a4", margin: 2.3cm)
#set text(size: 10.5pt, font: ("Libertinus Serif", "Noto Serif CJK SC", "SBL Hebrew"))
#set heading(numbering: "1.1")
#show link: underline
#show text.where(lang: "he"): set text(font: ("SBL Hebrew", "Noto Serif Hebrew", "DejaVu Serif"))

= 指示词

指示词是“这”“那”这种词语。它们可以作为名词或者形容词，不过即使作为名词，它也需要和指代的名词性数一致。

*这*

#table(columns: 3, stroke: none,
[], [*单数*], [*复数*],
[阳性], [#heb("zeh")], [#heb("'E<l.eh")],
[阴性], [#heb("zO't")], [#heb("'E<l.eh")],
)

复数形态是一样的。

*那*

#table(columns: 3, stroke: none,
[], [*单数*], [*复数*],
[阳性], [#heb("hw.'")], [#heb("hE<m.Ah") 或者 #heb("hEM")],
[阴性], [#heb("hiy'")], [#heb("hE<n.Ah") 或者 #heb("hEN")],
)

这里复数 -m 和 -n 的结尾和 _qatal_ 形态下第二人称复数的结尾是一样的。

作为名词出现在判断句里的时候，指示词一般出现在前方。

#heb("zeh dese' yAfeh") 这是美丽的草。

#heb("zO't Hay.Ah rAsA`") 这是邪恶的野兽。

作为形容词的时候，它表示定指，所以它本身和修饰的名词都要加上定冠词 #heb("ha")。

“这”在添加定冠词的时候是规则的。

#table(columns: 3, stroke: none,
[], [*单数*], [*复数*],
[阳性], [#heb("haz.eh")], [#heb("hA'E<l.eh")],
[阴性], [#heb("haz.O't")], [#heb("hA'E<l.eh")],
)

而“那”的复数形态不规则：

#table(columns: 3, stroke: none,
[], [*单数*], [*复数*],
[阳性], [#heb("hw.'")], [#heb("hAhEm.Ah") 或者 #heb("hAhEM") 或者 #heb("hal.Azeh")],
[阴性], [#heb("hiy'")], [#heb("hAhEn.Ah")],
)

虽然以 #heb("hE") 开头，但定冠词却是 #heb("hA") 而不是 #heb("ha")。而且，阳性复数形式还多了一个 #heb("hal.Azeh") 的形式，虽然极其少见，但确实见于圣经。阴性复数形式的 #heb("hEN") 无法加上定冠词，只剩下 #heb("hAhEn.Ah") 这个长形式了。

在罕见的情况下，会出现名词和指示词都不加定冠词的情况，例如 #heb("Sw.S zeh") 而不是 #heb("haS.w.S haz.eh")。这是没有规律的，只要看见了能认出来就可以了。

= 例文

#heb("hag.AN")

#heb("vay:hiy 'aHa:rEy had:VAriyM hA'El.eh vay:hiy haS.w.S rA`EV m:'Od:: vay:hiy badereK: hin.Eh gaN yAfeh 'a:ser lahEykAl:: vay:hiy bag.AN hayAfeh hahw.' dese' v:`EC p.:riy raV:: vay.O'mer haS.w.S zeh dese' yAfeh:: vay.O'kal haS.w.S 'et-ko.l-hade.se' v:'et-k.ol-hap.:riy 'a:ser ba.gA.N:: vat.O'mer ham.al:k.Ah 'el-ham.eleK: haS.w.S haze.h VAzaz hag.AN 'a:ser lahEykAl:: vay.O'mer ham.eleK: k.iy-zO't Hay.Ah rA`Ah:: vay.is:l:Hw. 'et-haS.w.S 'el-has,.Ade 'a:ser 'Ecel hAhAr:: vay.O'mer haS.w.S sAn.E<'tiy 'et-has.,Ade haz.eh v:'et-ham.eleK: hahw.' v:'et-hama.l:k.Ah hahiy' v:'et-hag.:mal.iyM hahEm.Ah v:'et-ha'a:twOnwOt hahEn.Ah")

== 词表

#heb("dereK:") 路

#heb("`EC") 树

#heb("Vzz") 劫掠

#heb("Hay.Ah") 野兽

#heb("sn'") 讨厌；这个动词是另一种变位方法，这里的 #heb("sAn.E<'tiy") 是第一人称单数形式。

#heb("s,mH") 开心

#heb("ywOM") 天，复数 #heb("yAmayiM")

== 注

这里的 #heb("ki.y") 起强调作用。

#heb("ki.y-zO't Hay.Ah rA`Ah") 这真是一只邪恶的野兽啊！

== 练习

翻译：

The king and the queen sat (_qatal_) in the garden and said, "This is a great (_lit._ big) day, because that evil beast cannot eat the fruit which is in this beautiful garden!" The camels and the female donkeys said, "We love this good king and this good queen because they've sent that horse to the field which is near the mountain." But the horse did not rejoice, because he did not like the grass which was in that field. And the horse said, "Those camels and those donkeys are wicked, and also that king and that queen are wicked!"

#heb("yAs:Vw. ham.eleK: v:ham.al:k.Ah bag.AN vay.O'm:rw. zeh ywOM gAdwOl k.iy lO' tO'kal haHay.Ah hAra`Ah hAhiy' 'et-hap.:riy 'a:ser b.ag.AN haze.h:: vay.O'm:rw. hag.:mal.iyM v:hA'a:twOnwOt 'Aha<b:nw. 'et-ham.eleK: haT.wOV haz.eh v:'et-ham.al:k.Ah haT.wOVAh haz.O't k.iy sAl:Hw. 'et-haS.w.S 'el-has.,Adeh 'a.ser: 'Ecel hAhAr:: v:lO' s,AmaH haS.w.S k.iy lO' 'Ahab 'et-hade.se' 'a:ser b.as.,Adeh hahw.':: vay.O'mer haS.w.S rA`iyM hag.:mal.iyM hAhEM v:ha'a:twOnwOt hAhEn.Ah v:gaM rA`iyM ham.eleK: hahw.' v:ham.al:k.Ah hahiy'::")
