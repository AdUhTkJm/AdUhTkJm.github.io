#import "@preview/cuti:0.4.0"
#import "heb.typ": heb, heb-sheet, ltr-island

#set document(title: "希伯来语学习笔记 (1)")
#set page(paper: "a4", margin: 2.3cm)
#set text(size: 10.5pt, font: ("Libertinus Serif", "Noto Serif CJK SC", "SBL Hebrew"))
#set heading(numbering: "1.1")
#show link: underline
#show text.where(lang: "he"): set text(font: ("SBL Hebrew", "Noto Serif Hebrew", "DejaVu Serif"))

// 词形变换行一律按 LTR 顺序写：左边是变换后的形式，箭头指回词根形式，
// 例如 `#heb("hak.iSE.'") #large-arrow #heb("k.iSE.'") [王座]`。
// 箭头要走 `ltr-island`，否则 PDF 会把箭头并进相邻的 RTL run、整行镜像
// （网页上 `<span dir="rtl">` 自带隔离，不会出这个毛病）。
#let large-arrow = [#set text(size: 18pt); #ltr-island[$<-$]]

= 定冠词

希伯来语没有不定冠词，但是有定冠词前缀 #heb("h")。它的使用规则是，将名词的第一个辅音双写，然后在词首添加 #heb("ha")：

#block(inset: (y: 0.6em))[
  #heb("hak.iSE.'") #large-arrow #heb("k.iSE.'") [王座] \
  #heb("haS.v.S") #large-arrow #heb("Sv.S") [马] \
  #heb("has.,Adeh") #large-arrow #heb("s,Adeh") [田野] \
  #heb("ham.eleK:") #large-arrow #heb("meleK:") [王]
]

注意，#heb("k.iSE.'") 以 #heb("k.") 开头，它本身就含有一个 dagesh。在添加 #heb("ha") 后，它实际上只是将 dagesh 转变为了 dagesh forte；在现代希伯来语发音中，这两者其实已经失去了所有区别。

== 特例

这种古代语言很难没有什么特例。

首先，我们知道希伯来语有五个字母是不能双写的：#heb("hHr'`")。不能双写，意味着短音 `a` 所在的音节不能闭合，而希伯来语并不喜欢这样。所以，既然没法双写，只好转而去修改 `a`，把它换成长音了。长音 `a` 就没有不能出现在非重读开音节的限制：

#block(inset: (y: 0.6em))[
  #heb("hArO's") #large-arrow #heb("rO's") [头] \
  #heb("hA`iyr") #large-arrow #heb("`iyr") [城市] \
  #heb("hA`iys") #large-arrow #heb("'iys") [男人]
]

不过，这个规律只对 #heb("'`r") 这三个辅音有效。对于 #heb("hH")，它反而回归到普通的 #heb("ha") 了：

#block(inset: (y: 0.6em))[
  #heb("haHOdes") #large-arrow #heb("HOdes") [月份] \
  #heb("hahEykAl") #large-arrow #heb("hEykAl") [宫殿]
]

最后，还有例外中的例外。如果已经以 `ha` 开头了，加上定冠词就有连续的两个了，这样太重复了。所以，如果词语的开头是 #heb("HA")，不重读的 #heb("`A") 或是不重读的 #heb("hA")，定冠词本身就会变成 #heb("he")：

#block(inset: (y: 0.6em))[
  #heb("he`AriyM") #large-arrow #heb("`AriyM") [城市 (pl.)] \
]

== 不规则变形

有的是定冠词不规则，有的是词语本身的元音变化，有的全都有。

#block(inset: (y: 0.6em))[
  #heb("hA`AM") #large-arrow #heb("`aM") [国家] \
  #heb("hA`AreC") #large-arrow #heb("`ereC") [土地] \
  #heb("hag.AN") #large-arrow #heb("g.aN") [花园] \
  #heb("hAhAr") #large-arrow #heb("har") [山]
]

= 语序

和俄语类似，希伯来语的判断句是没有系动词的，而且不管什么时态都没有。

#heb("v:sAM `iyr") [и там город/那里有个城市。]

#heb("'ay.Eh hac.edeq") [где справедливость?/正义在哪里？]

如果有动词的话，一般是 VSO 的顺序。比如

#heb("vay.O'mer haS.w.S 'ay.Eh hac.edeq") [马说：“正义在哪里？”]

这里的“说” #heb("vay.O'mer") 就是第一个词，而主语 #heb("haS.w.S") 则放在动词之后。

形容词一般放在名词之后。

#heb("k.iS.E' g.AdwOl") [大王座]

#heb("s,adeh qATON") [小田野]

而修饰形容词的副词则也放在形容词之后。

#heb("k.iS.E' g.AdwOl m:'Od") [非常大的王座]

= 例文

#heb("ham.eleK: v:haS.w.S")

#heb("vay:hiy har g.AdwOl b.:'ereC k.:na'aN v:sAM `iyr vay:hiy hEykAl 'Ecel hA`iyr vay:hiy hahEykAl g.AdwOl m:'Od:: vay:hiy '.iys b.:twOK: hahEykAl vay:hiy hA'iys meleK: v:ham.eleK: yOsEV `al-k.iSE.':: vay:hiy hak.iS.E' g.AdwOl m:'Od:: vay:hiy s,Adeh 'Ecel hahEykAl vay:hiy has,.Adeh qATON m:'Od:: vay:hiy Sw.S b:.twOK: has,.Adeh:: vay.O'mer haS.v.S hin.Eh hame.leK: yOsEV `al-ki.SE.' g.AdwOl b.:twOK: hEykAl g.AdwOl va'a:niy yOsEV b.:twOK: s,Adeh qATON 'ay.Eh hac.edeq::")

可以看到，这里经常用 #heb("vay:hiy") 表示“存在”。这和俄语有一定的类似之处，可以通过这个词来引入一个新的东西，例如 #heb("vay:hiy heykAl 'Ecel HA`iyr") 这句话可以大致看作是 Есть дворец рядом с городом，明确写出 `Есть` 表示存在。当然，不写也是可以的。

接下来是一些翻译小练习。英语原文如下：

The king is in the middle of the palace. The palace is big. The king is sitting on a throne. The throne is very big. The queen is next to the palace. The queen is in the middle of the garden. The garden is very big. The horse is in the middle of the field. The field is very small. Where is the justice?

#heb("ham.eleK: b.:twOK: hahEykAl:: hahEykAl g.AdwOl:: ham.eleK: yOsEV `al-k.iSE.':: haki.SE. g.AdwOl m:'Od:: ham.al:k.Ah 'Ecel hahEykAl:: ham.al:k.Ah b.:twOK: hag.AN:: hagA.N g.AdwOl m:'Od:: haS.v.S b.:twOK: has,.adeh:: has,.adeh qATON m:'Od:: 'ay.Eh hac.edeq")

= 技术细节：希伯来语 DSL

一部分字符从左往右，一部分从右往左，手动编辑实在难搞。所以，我的选择是直接使用一个仅由 ASCII 构成的 DSL：一个希伯来语字符对应一个辅音字母，按照逻辑顺序顺序。辅音字母后可以有附标，顺序任意，在编译时会按照 Unicode 规范顺序 (NFC) 重排。其实网上有很多希伯来语资料的 Unicode 都是很混乱的。

码表如下：

#heb-sheet()

还有一个问题，就是 Libertinus Serif 支持希伯来字母，但不支持附标，所以带附标的音节和不带的效果不一样。我们将 `lang=he` 的字体统一为 SBL Hebrew 就可以了。有的字体，比如 Noto Serif Hebrew，不支持将 #heb("wO") 作为 _mater lectionis_ 时的附标渲染在右上角。
