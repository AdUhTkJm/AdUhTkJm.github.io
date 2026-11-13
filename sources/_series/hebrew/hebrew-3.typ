#import "@preview/cuti:0.4.0"
#import "heb.typ": heb, heb-sheet, ltr-island, to

#set document(title: "希伯来语学习笔记 (3)")
#set page(paper: "a4", margin: 2.3cm)
#set text(size: 10.5pt, font: ("Libertinus Serif", "Noto Serif CJK SC", "SBL Hebrew"))
#set heading(numbering: "1.1")
#show link: underline
#show text.where(lang: "he"): set text(font: ("SBL Hebrew", "Noto Serif Hebrew", "DejaVu Serif"))

= 名词的性数变化

== 性

希伯来语的名词也分阴阳。阳性名词没有特别的词尾，而阴性名词一般以 #heb("_-^Ah") 结尾，不过也有一些会以 #heb("_-t") 结尾。在某些情况下，可以通过在阳性名词末尾加上 #heb("_-^Ah") 的方式来将它变为阴性：

#to("Sw.S", "Sw.SAh")

不过，有少量的阴性名词并没有这些后缀。

#heb("'EM") [母亲] \
#heb("'AtwON") [驴子 (f.)] \
#heb("`iyr") [城市] \
#heb("'ereC") [土地] 

还有一小部分词语同时具有两种变格方式，称作 _common gender_，一般以 (c) 标注。

#heb("cO'N") [羊群] \
#heb("g.aN") [花园] \
#heb("'vOr") [光]

== 复数

一般情况下，复数的变化还是很简单的。

对于阳性名词，添加 #heb("_-^iyM")；对于阴性名词，去掉原有的后缀并添加 #heb("_-^wOt")。比如：

#to("Sw.S", "Sw.SiyM") \
#to("Sw.SAh", "Sw.SwOt")

如果最后以 mater lectionis 的 #heb("h") 结尾，#heb("h") 和前面的元音也会一并消失。

#to("sA,deh ", "sA,dwOt")

不过 #heb("sA,deh") 是阳性名词，却使用了阴性后缀；后文会提到这些特殊的不规则变化。

然而，随着重音变化，前半部分的元音也可能会随之弱化。

*远处的元音*

在重音节之前，原本含有长元音的开音节现在将会变为 schwa。这是因为在离重音至少两个音节远的地方（称作 _propretonic_），希伯来语是不能含有长元音的。

#to("d.AVAr", "d.:VAriyM")

由于喉音无法接受 schwa，我们只能将其变为 #heb("^a:")。

#to("HAVAM", "Ha:VAmiyM") [智者]

动词的主动分词是特殊的。虽然我还完全不知道它是什么，但它有这样的元音标点：#heb("^O^E^")。在变为复数时，需要将它的倒数第二个元音（重音前的那一个，也就是 _pretonic_）改为 schwa。同理，在是喉音的时候会变为 #heb("^a:")。

#to("SOfEr", "SOf:riyM") [抄写员] \
#to("sOfET", "sOf:TiyM") [法官] \
#to("kO.hEN", "kO.ha:niyM") [牧师] \

*E-词* (_Segolate_)

希伯来语中有不少 #heb("^e^e^") 这样的词语，它们的重音往往落在第一音节。这些词语称作 _segolate_，毕竟 #heb("^e") 的官方名称是 segol。它似乎没有中文翻译，我将它称作 E-词。它们的来源是，古代语言中有词尾的复辅音，例如 #heb("meleK:") 古代可能读作类似 /malk/，后来音节系统改变，人们不得不插入一个 #heb("^e")。

还有一些其他形态的 E-词。如果第二个辅音是喉音，那么 #heb("^e") 会变为 #heb("^a")，重音仍然在词首：

#heb("na`ar") [少年]

对于阴性名词，元音模式会有所不同。原本的元音重新出现了，所以 #heb("meleK:") 才会变为 #heb("mal:k.Ah")。

它们的复数几乎全部是 #heb("^:^A") 形态的。对于不能接 schwa 的喉音会变成 #heb("^:a^A")，和之前的 propretonic 变化是一致的。 比如

#to("meleK:", "m:lAkiyM") \
#to("`eVed", "`a:VAdiyM") \
#to("`eled", "`:lAdiyM") [孩子]

#to("'ereC", "':rAciyM") \
#to("SEfer", "S:fAriyM") [信，卷轴]

#to("na`ar", "n:`AriyM") \
#to("mal:k.Ah", "m:lAkwOt")

在 #heb("mal:k.Ah") 的情况下， #heb("k") 的 #heb("d.AgEs") 消失了，这是因为它前面变成了开音节 #heb("lA")。

*辅音延长* (_Geminate_)

有一些词语的辅音其实是双写的，只是在单数形态下缩合了。例如 #heb("`aM") [国家]，它的最后一个辅音其实是双写的 #heb("m")，但是词尾辅音不能使用重强调点。在复数形态下，它的强调点会回来。一般单音节词都会经历辅音延长。

#to("`aM", "`aMi.ym")

它前方的元音也会缩短，毕竟添加强调点后将会变为非重音的闭音节。原本希伯来语只有 a, i, u 三个辅音，因此 e, i 均会缩短到 i，而 o, u 均会缩短为 u。

#to("HOq", "Huq.iyM") [雕塑] \
#to("lEV", "lib.iyM") [心]

如果无法双写，前方的元音会被迫成为长元音。

#to("har", "hAriyM")

*不规则变化*

有些词的变化就是不规则的，那也没办法。

#to("g.AmAl", "g.:mal.iyM") [骆驼] \
#to("'iys", "'a:nAsiyM") [男人] \
#to("ywOM", "yAmiyM") [夜晚] \
#to("b.EN", "b.AniyM") [儿子] \
#to("ki.S.E'", "ki.S:'wOt") \
#to("b.at", "b.AnwOt") [女儿] \
#to("'is.Ah", "nAsiyM") [女人] \
#to("`iyr", "`AriyM")

可以看到，有些词语虽然是阳性，却使用了阴性后缀，反之亦然。这些词语也是特殊的。不过，复数形态下，它们的性也不会改变。

#to("sul:HAN", "sul:HAnwOt") \
#to("sAnAh", "sAniyM") [年]

== 双数

希伯来语中，双数用得不多。主要是在成对出现的部位（双手），以及一些时间、数字上的时候使用。方式是添加 #heb("_-^ayiM") 后缀。

#to("yAd", "yAdayiM") [手, f.] \
#to("ywOM", "ywOmayiM") [日子]

对于 E-词，它们也会还原为古形态，出现原本的辅音。

#to("regel", "rag:layiM") [腿, f.]

对于阴性名词，#heb("_-^Ah") 中的 #heb("h") 会变为 #heb("_-^tayiM")。

#to("sAnAh", "s:nAtayiM")

这里也发生了元音弱化，开头的 #heb("sA") 是长音的开音节，因此变为了 schwa。

= 例文

#heb("g.:mal.iyM va'a:twOnwOt")

#heb("vay:hiy `wOd mis:t.eh VahEykAl:: vay.AVO'w. m:lAkiyM w.m:lakwOt `al-g.:mal.iyM v:`al-'a:twOnwOt 'el-ham.is:t.eh:: vay.Es:Vw. v:ham.:lAkiyM v:ham.:lAkwOt b.ahEykAl ywOmayiM vay.O'k:lw. maT:`am.iyM:: vay.Es:Vw. hag.:mal.iyM v:hA'a:twOnwOt b.as,A.deh ywOmayiM vay.O'k:lw. dese':: vay.O'mer haS.w.S 'wOy liy ham.:lAkiyM v:ham.:lAkwOt v:hag.:mal.iyM v:hA'a:twOnwOt s,:kE`iyM va'a:niy rA`EV")

== 练习

将这段话的所有名词变为复数：

#heb("ham.eleK: v:ham.al:k.Ah bahEykAl `al-k.iS.Eh 'Ecel sul:HAN:: hab.EN v:hab.at v:hA`eVed b.ak.ereM:: haS.w.S v:hag.AmAl v:hA'a:twON b.as.,Adeh")

修改后的文段是

#heb("ham.:lAkiyM v:ham.:lAkwOt bahEykAliyM `al-k.iS:'wOt 'Ecel sul:HAnwOt:: hab.AniyM v:hab.AnwOt v:hA`a:VAdiyM b.ak.:ramiyM:: haS.w.SiyM v:hag.:mAl.iyM v:hA'a:twOnwOt b.as.,AdwOt")

翻译：

The horse is in the field with the camels and with the donkeys. The camels and the donkeys are full, but the horse is hungry. Where are the delicacies? The delicacies are inside the palace, with the kings and with the queens. And where is the grass? The grass is inside the camels and the donkeys.

#heb("haS.w.S b.as,A.deh `iM-hag.:mal.iyM v:`iM-hA'a:twOnwOt:: hag.:mal.iyM v:hA'a:twOnwOt s,:kE`iyM v:haS.w.S rA`EV:: 'ay.Eh ham.aT:`am.iyM:: ham.aT:`am.iyM b.ahEykAl `iM-ham.:lakiyM v:`iM-ham.:lakwOt:: v:'ay.Eh hadese':: hadese' b.ag.:mAl.iyM v:b.A'a:twOnwOt")
