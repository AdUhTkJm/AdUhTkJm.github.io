#import "@preview/cuti:0.4.0"
#import "heb.typ": heb, heb-sheet, ltr-island, to

#set document(title: "希伯来语学习笔记 (5)")
#set page(paper: "a4", margin: 2.3cm)
#set text(size: 10.5pt, font: ("Libertinus Serif", "Noto Serif CJK SC", "SBL Hebrew"))
#set heading(numbering: "1.1")
#show link: underline
#show text.where(lang: "he"): set text(font: ("SBL Hebrew", "Noto Serif Hebrew", "DejaVu Serif"))

= 动词的未完成体

未完成体又称作 _qal yiqtol_。它通过添加前缀来改变形态，所以也称作前缀变化。它的形态如下：

*阳性形式*

#table(columns: 3, stroke: none, align: right,
[], [*单数*], [*复数*],
[第一人称], [#heb("'eq:TOl")], [#heb("niq:TOl")],
[第二人称], [#heb("t.iq:TOl")], [#heb("t.iq:T:lw.")],
[第三人称], [#heb("yiq:TOl")], [#heb("yiq:T:lw.")],
)

拉丁转写：

#table(columns: 3, stroke: none, align: right,
[], [*单数*], [*复数*],
[第一人称], ['e-], [ni-],
[第二人称], [ti-], [ti-...-u],
[第三人称], [yi-], [yi-...-u],
)

这里的标点都是 #heb("^:^O^")，只有在末尾获得额外音节 -u 的时候，会将那个长音 o 变为发音的 schwa。这也是一种 _pretonic reduction_。由于前缀总是以元音结尾，首个 schwa 总是静音的。

*阴性形式*

#table(columns: 3, stroke: none, align: right,
[], [*单数*], [*复数*],
[第一人称], [#heb("'eq:TOl")], [#heb("niq:TOl")],
[第二人称], [#heb("t.iq:T:liy")], [#heb("t.iq:TO<l:nAh")],
[第三人称], [#heb("t.iq:TOl")], [#heb("t.iq:TO<l:nAh")],
)

拉丁转写：

#table(columns: 3, stroke: none, align: right,
[], [*单数*], [*复数*],
[第一人称], ['e-], [ni-],
[第二人称], [ti-...-i], [ti-...-na],
[第三人称], [ti-], [ti-...-na],
)

阴性的 2p, 3p 是一样的。而且，这里的 3fs 和 2ms 是一样的，靠上下文区分。

对于标点，在 2fs 处依然是最后出现 -i 就将长音 o 变为 schwa。而 2fp/3fp 的标点回归正常，因为重音移动了。额外的标点只是为 l 增加了一个静默的 schwa 而已。

如果第二或第三个辅音是喉音，需要将 schwa 改为超短音 a，和往常一样。不过，还有一个新的音变：在这种情况下，没有后缀的那些形态需要将 schwa 改为短音 a。

考虑 #heb("s'l") “问”以及 #heb("sm`") “听”：

#heb("yis:'al") [3ms] \
#heb("yis:ma`") [3ms] \
#heb("tis:'a:lw.") [2mp]

== 用法

希伯来语用*未完成体表示未来*。

#heb("vay.O'mer meleK: k.w.s 'es,:rOF 'et-hA`iyr")

[И сказал король: *сожгу* город.]

这里 #heb("s,rf") 是“烧”的词根，使用未完成体；而 сжечь (сожгу, сожжёшь) 是完成体。这是因为，希伯来语的完成体侧重动作实现与否，而未实现的动作自然在未来；俄语的完成体侧重动作是否已经完整结束，而“现在正在结束”并不是合理的语义，因此这个时态和体的结合被推向了未来。

在表达未来持续的情况下，希伯来语依然使用未完成体，而俄语则需要复合将来时 быть делать。

未完成体还可以表示习惯动作，这个和俄语一样。

同时，未完成体也可以表示情态，比如意愿、可能之类的。

#heb("'es,:rOF 'et-HA`iyr")

根据语境的不同，可以表示“我也许会/将会/能烧掉这个城市。”

最后，未完成体还可以作为命令式。考虑 #heb("drs") “寻求”：

#heb("ti.d:rOsw. sAlwOM")

[去寻求和平吧！]

不同人称也是可以的：

#heb("vay.O'mer ham.:lAkiyM nis,:rOf 'et-hA`iyr")

[国王们说：让我们烧掉这个城市吧。]

#heb("yid:r:sw. ham.:lAkiyM sAlwOM")

[让国王们去寻求和平吧。]

= 例文

#heb("ham.il:HAmAh")

#heb("vay.O'mer meleK: k.w.s 'es,:rOF 'et-hA`iyr b.A'Es:: vay.O'mer ham.eleK: 'wOy-liy kiy tis:,rOF 'et-Ha`iyr b.A'Es:: vat.O'mer mal:k.at 'e:dwOM 'el:k.Od 'et-hA`AM:: vay.O'mer ham.eleK: 'wOy-liy kiy til:k.:diy 'et-hA`AM:: vay.O'm:rw. kol-ham.:lAkiyM nis:,rOF 'et-hahEykAl b.A'Es:: vay.O'mer ham.eleK: 'wOy-liy kiy tis:,r:fw. 'et-hahEykAl b.A'Es:: vat.O'mar:nAh kol-ham.:lAkwOt nim:lOK: b.A'AreC:: vay.O'mer ham.eleK: 'wOy-liy kiy tim:lO<k:nAh bA'AreC:: vay.O'mer haS.w.S 'ay.Eh hac.edeq hame.leK: yid:rOs sAlwOM v:ham.:lAkiyM v:ham.:lAkwOt yig:n:bw. kEliyM v:gaM yid:r:sw. mil:HAmAh")

在这里 #heb("meleK: kw.s") 和 #heb("mal:k.at 'e:dwOM") 实际上是“附着状态”（#heb("S:miykw.t")），或者说是属格的连读法。这个暂时没有介绍过，总之知道意思就可以了。

== 词表

#heb("kw.s") 库施，古代王国。有时会被译作埃塞俄比亚，但是这并不准确（并非现代的埃塞俄比亚）。这是因为在后续翻译时，希腊人选择了使用他们对埃及以南地区的统称 Αἰθιοπία，晒黑面庞者的土地（αἰθι- 是燃烧，而 οπ- 是脸）。现代的埃塞俄比亚在古代主要对应的是阿克苏姆帝国，它位于库施的东南方。

#heb("'es") 火 (f.)

#heb("k.ol-") 全部的。这里的 #heb("^o") 是短音 o。

#heb("drs") 寻求

#heb("mlk") 统治

#heb("s,rf") 燃烧

#heb("lkd") 占领

#heb("g.aM") 甚至，也 (also, even)

== 练习

翻译：

The king said to the queen, "Woe is me, because the kings and the queens seek war, whereas I seek peace." But the queen said, "Also shall I seek war, for the kings and the queens have stolen the vessels which I love. And now you must capture the palaces, burn the cities, capture the people and rule in the lands." But the king said, "I do not want the lands, because I only want the vessels!"

#heb("'Amar ham.eleK: 'el-ham.al:k.Ah 'wOy-liy kiy yid:r:sw. ham.:lAkiyM va'a:niy ham.:lAkwOt mil:HAmAh v:'ed:rOs sAlwOM:: v:'Am:rAh ham.al:k.Ah gaM 'ed:rOs 'a:niy mil:HAmAh kiy gAn:bw. ham.:lAkiyM v:ham.:lAkwOt 'et-hak.EliyM 'a:ser 'e'a:hOb:: v:`at.Ah til:k.Od 'et-hahEykAliyM v:tis,:rOF 'et-he`AriyM v:til:k.Od 'et-hA`AM v:tim:lOK: b.A'a:rACwOt:: v:'Amar ham.eleK: lO' 'eH:fOC b.A'a:rACwOt k.iy raq 'eH:fOC b.ak.EliyM")

这里 #heb("'ereC") 的复数是 #heb("'a:rAcwOt")，而 #heb("raq") 是“仅仅”的意思。

而且，#heb("'AriyM") 的定冠词是 #heb("he")，这也是第一篇文章中提到的特例：非重读的喉音和 a 在一起，就会将定冠词的 #heb("ha")/#heb("hA") 改为 #heb("he")。
