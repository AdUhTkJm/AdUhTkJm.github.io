#import "@preview/cuti:0.4.0"
#import "heb.typ": heb, heb-sheet, ltr-island, to

#set document(title: "希伯来语学习笔记 (7)")
#set page(paper: "a4", margin: 2.3cm)
#set text(size: 10.5pt, font: ("Libertinus Serif", "Noto Serif CJK SC", "SBL Hebrew"))
#set heading(numbering: "1.1")
#show link: underline
#show text.where(lang: "he"): set text(font: ("SBL Hebrew", "Noto Serif Hebrew", "DejaVu Serif"))

= 形容词

希伯来语的形容词会按照性、数变化。以 #heb("TwOV") “好”为例：

#table(columns: 3, stroke: none,
[], [*单数*], [*复数*],
[阳性], [#heb("TwOV")], [#heb("TwOViyM")],
[阴性], [#heb("TwOVAh")], [#heb("TwOVwOt")]
)

如果修饰阳性和阴性的组合，会变为阳性复数。

这和名词的变化是完全一致的。不过，名词的复数变化涉及到元音弱化，而形容词也是一样。下面提到的变化会在三种变形中同时出现，不过这里主要以 #heb("_-^iyM") 作为例子。

== 元音弱化

在离重音至少两个音节的位置，元音将会弱化为 schwa。如果辅音无法接受 schwa，那么会变为超短 a。

#to("g.AdwOl", "g:dwOliyM") 大 \
#to("HAzAq", "Ha:zAqiyM") 强

== 辅音延长

复习一下名词的辅音延长。有一些词语的末尾辅音是隐藏的双重辅音，例如 #heb("`aM")。所以变为复数的时候，辅音会添加强调点，而此前的元音会缩短。

#to("`aM", "`aMi.ym") \
#to("HOq", "Huq.iyM") 雕塑 \
#to("lEV", "lib.iyM") 心

如果无法双写，前方的元音会被迫成为长元音。

#to("har", "hAriyM")

形容词也会有同样的现象。比如

#to("raV", "rab.iyM") 多 \
#to("ra`", "rA`iyM") 坏，邪恶

“邪恶”还有一个词是 #heb("rAsA`")。

== #heb("h") 结尾的名词

这些名词的变格方法是特殊的。如果以 #heb("h") 结尾，那么一定以 #heb("_-^eh") 结尾。以 #heb("yAfeh") “美丽，帅气”为例：

#table(columns: 3, stroke: none,
[], [*单数*], [*复数*],
[阳性], [#heb("yAfeh")], [#heb("yAfAh")],
[阴性], [#heb("yAfiyM")], [#heb("yAfwOt")]
)

也就是将最后的 -eh 去掉，以剩余部分作为词干变形。

== 主动分词

主动分词的形态是 #heb("^O^e^")。它的短音 e 将会变为 schwa。

#to("yOsEV", "yOs:ViyM")

但是特殊的是，它的阴性形态有两种形式。

#to("yOsEV", "yOs:VAh") \
#to("yOsEV", "yOseVet")

== 不规则变形

#to("'aHer", "'aHe<ret") 其他 \
#to("qATON", "q:Tan.Ah q:Tan.iyM q:Tan.wOt") 小（额外插入一个 -nn-） \
#to("mAtwOq", "m:tw.qAh m:tw.qiyM m:tw.qwOt") 甜（中间的 o 变为 u）

虽然书上说 #heb("mAtwOq") 没有阴性复数，但这只是因为《圣经》中恰好没有出现而已。它的阴性复数应当依然是正常的 #heb("m:tw.qwOt")。

#heb("qATAN") 和 #heb("qATON") 是同一个词的两种不同形式。#heb("qATAN") 一般用作定语，而 #heb("qATON") 一般用作表语。但这两个形式的其他形态都是以 #heb("q:Tan._-") 作为词干的。

= #heb("k.ol-") 的使用

#heb("k.Ol") 在单独使用的时候，是表示“全部”的名词。在作为前缀的时候，它根据后面的名词的单复数和定指，会表示不同的意思。

*单数，不定*

表示“每个”。

#heb("k.ol-mat.AnAh") 每个礼物

*复数，不定*

希伯来语不允许这样的搭配。

*单数/复数，定指*

表示“全部”，“……中的所有”。

#heb("hag.:mal.iyM v:hA'a:twOnwOt yO'k:lw. 'et-k.ol-had.ese' 'a:ser b.as,.Adeh")

骆驼和驴子吃了草地上的所有草。

#heb("hA`iz.iyM t.O'ka<l:nAh 'et-k.ol-hak.EliyM 'a:ser lahEykAl")

山羊吃了宫殿里的所有容器。

这里的 #heb("l:") 在 #heb("kE.liyM") 之前，表示“拥有”、“属于”。

= 例文

#heb("ham.at.AnwOt")

#heb("vay:hiy 'aHa:rEy ham.il:HAmAh vay.is:l:Hw. ham.:lAkiyM v:ham.:lakwOt mat.AnwOt rab.wOt 'el-hahEykAl:: vay.is:l:Hw. d:Vas mAtwOq va'a:VAniyM y:qArwOt v:`ugAh g:twOlAh w.b:gAdiyM yAfiyM v:`a:VAdiyM Ha:zAqiyM:: vay.O'mer ham.eleK: v:ham.al:k.Ah TwOV had.AVAr:: vay.is:l:Hw. gaM g.:mal.iyM g.:dwOliyM va'a:twOnwOt rab.wOt:: vay.O'mer haS.w.S lO'-TwOV had.AVAr k.iy hag.:mal.iyM v:hA'a:twOnwOt y.O'k:lw. 'et-ko.l-had.eseh 'a:ser b.as.,Adeh:: vay.is:l:Hw. gaM `iz.iyM rab.wOt:: vay.O'm:rw. ham.eleK: v:hama.l:k.Ah lO'-TwOV had.AVAr k.iy hA`iz.iyM t.O'ka<l:nAh 'et-k.ol-hak.EliyM 'a:ser lahEykAl::")

== 词表

#heb("matA.nAh") 礼物

#heb("rab") 多

#heb("mAtwOq") 甜

#heb("yAqAr") 珍贵

#heb("yAfeh") 美丽

#heb("HAzAq") 强

#heb("'eVeN") 石头 [f.]，复数 #heb("'a:VAniyM")

#heb("`ugAh") 蛋糕

#heb("b.eged") 长袍，复数 #heb("b.:gAdiyM")

#heb("slH") 送出。注意和 #heb("SlH") “原谅”区分。

== 注

这里说 #heb("vay.O'mer TwOV had.AVAr")，看起来是形容词在名词前。这是因为 #heb("TwOV") 并不是作为定语修饰 #heb("had.AVAr") 的，而是作为表语，形成一个完整的句子“这件事是好的”。表语一般在前面，表示强调。

== 练习

翻译：

The king and the queen wrote a letter to the kings and to the queens who had sent the gifts, and they said, "We love the gifts that you sent". But in truth, the king and the queen loved the honey and gemstones and the cake and the garment and the slaves, and also the camels and donkeys, but they did not love the goats, because the goats had eaten the honey and the cake, and also the garments.

#heb("vay.ik:t.:bw. ham.eleK: v:ham.al:k.Ah SEfer 'el-ham.:lAkiyM v:'el-ham.:lAkwOt 'a:ser sAl:Hw. 'et-ham.at.AnwOt:: vay.O'm:rw. 'Aha<b:nw. 'et-ham.at.AnwOt 'a:ser s:laH:te.M:: v:b:'e:met 'Ah:bw. 'et-had.:Vas v:'et-hA'a:VAniyM hay:qArwOt v:'et-hA`ugAh v:'et-hab.eged v:'et-hag.:mal.iyM v:'et-hA'a:twOnwOt 'et-ha`a:VAdiyM w:l'O 'Ah:bw. 'et-hA`iz.iyM k.iy 'Ak:lw. hA`iz.iyM 'et-had.:Vas v:'et-hA`ugAh v:gaM 'et-hab.:gAdiyM::")

*词表*

#heb("ktb") 写

#heb("S<Efer") 书。或者这里使用 #heb("mik:t.AV") “信”更合适，虽然书上没有这个词。

*注*

希伯来语中，完成体可以表示持续的情态动作，例如知道、喜欢等。所以这里 #heb("'hb") 使用的也是 _qatal_。
