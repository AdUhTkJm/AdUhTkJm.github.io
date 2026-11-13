#import "@preview/cuti:0.4.0"
#import "heb.typ": heb, heb-sheet, ltr-island, to

#set document(title: "希伯来语学习笔记 (4)")
#set page(paper: "a4", margin: 2.3cm)
#set text(size: 10.5pt, font: ("Libertinus Serif", "Noto Serif CJK SC", "SBL Hebrew"))
#set heading(numbering: "1.1")
#show link: underline
#show text.where(lang: "he"): set text(font: ("SBL Hebrew", "Noto Serif Hebrew", "DejaVu Serif"))

= 动词的完成体

完成体称作 _qal qatal_，它会随着人称和性变化。完成体的变位方式也称作后缀变化，因为变化的形式就是加后缀。

这个 qatal 的名称是来自样板动词 #heb("qTl") [杀]。它在这个模式下的第三人称阳性形式会变为 #heb("qATal")，故而得名。

*阳性变化*

#table(columns: 3, stroke: none, align: right,
[], [*单数*], [*复数*],
[第一人称], [#heb("qATa<l:t.iy")], [#heb("qATa<l:nw.")],
[第二人称], [#heb("qATa<l:t.A")], [#heb("q:Tal:t.eM")],
[第三人称], [#heb("qATal")], [#heb("q|AT:lw.")],
)

换言之，就是如下的后缀表：

#table(columns: 3, stroke: none,
[], [*单数*], [*复数*],
[第一人称], [-ti], [-nu],
[第二人称], [-ta], [-tem],
[第三人称], [-$emptyset$], [-u],
)

元音模式基本都是长音 A -- 短音 a -- schwa，但是第二人称复数的首个元音，以及第三人称复数的第二个元音会变为 schwa。

*阴性变化*

#table(columns: 3, stroke: none, align: right,
[], [*单数*], [*复数*],
[第一人称], [#heb("qATa<l:t.iy")], [#heb("qATa<l:nw.")],
[第二人称], [#heb("qATa<l:t.:")], [#heb("q:Tal:t.eN")],
[第三人称], [#heb("qAT:lAh")], [#heb("qAT:lw.")],
)

拉丁转写：

#table(columns: 3, stroke: none,
[], [*单数*], [*复数*],
[第一人称], [-ti], [-nu],
[第二人称], [-tə], [-ten],
[第三人称], [-ah], [-u],
)

它跟阳性形态只有三个不一样。

在涉及到 #heb("bkdpgt") 的时候，需要按照常用的规则为它们打上 #heb("dA.gEs")。也就是说，如果这个辅音开启了一个新的音节，那么需要强调点；否则，就不需要。

对于无法加上 schwa 的辅音，我们和往常一样，将其改为 #heb("'a:")。

第一人称复数有一个特殊情况：当词根以 #heb("N") 结尾的时候，它会和后缀的 #heb("n") 合在一起形成 #heb("n.")。这个时候末尾的辅音不再是 schwa，而是 #heb("^a")。

动词的直接宾语用可分介词 #heb("'et-") 标记，一般标记只出现在宾语含有定冠词 #heb("ha") 的情况下。

= 例文

#heb("hak.EliyM")

#heb("vay:hiy bam.is:te.h vay.O'mer ham.eleK: 'el-ha`eVed v:'el-hasi.f:HAh hAVw. 'et-hak.EliyM k.i HAfac:nw. b:yayiN:: v:ha`eVed v:hasif:HAh '|Am:rw. lO' yAda`:nw. 'ay.Eh hak.EliyM vay.'Omer hame.leK 'el-ha`eVed hin.Eh gAn<aV:ta. 'et-hakE.liyM:: v:hA`eVed 'Amar lO' gAna<b:ti.y 'et-hak.EliyM:: vay.O'mer hame.leK: 'el-hasi.f:HAh hin.Eh gAna<b:t:. 'et-hak.EliyM:: v:has.f:HAh '|Am:rAh lO' gAna<b:t.iy 'et-hak.EliyM:: vay.O'mer ham.eleK: 'el-ham.:lAkiyM v:'el-ham.:lAkwOt 'a:ser b.ami.s:te.h hin.Eh g:nab:t.eM 'et-hak.EliyM:: v:hEm.Ah '|Am:rw. lO' gAna<b:nw. 'et-hak.EliyM v:`at.ah HAfac:nw. b:m.il:HAmAh ")

== 词表

#heb("k:.liy") 容器，复数为 #heb("k.EliyM")

#heb("sif:HAh") 女仆

#heb("'mr") 说

#heb("yd`") 知道

#heb("gnb") 偷盗

#heb("Hfc") 想要，支配介词 #heb("b.:")

#heb("'kl") 吃

#heb("lqH") 拿

#heb("ysV") 坐；生活

#heb("'hb") 爱，喜欢

#heb("`at.Ah") 现在

#heb("mil:HAmAh") 战争

#heb("'a:ser") 谁，哪个；这里是从句引导词

#heb("hEm.Ah") 第三人称复数

#heb("k.iy") 因为

#heb("lO'") 不

== 练习

翻译：

The horse had taken the fruit and the meat and the bread, but the horse had not stolen the vessels. The horse did not know where the vessels were. But the horse said to the camels and the (female) donkeys, "You have taken the vessels!" because he did not like the camels or the donkeys. The camels and the donkeys had not stolen the vessels, but they ate the fruit and the meat and the bread because they liked the food and did not like the horse.

#heb("lAqaH haS.w.S 'et-hap.:riy v:'et-hab.As,Ar v:'et-hal.eHeM 'a:VAl lO' gAnab haS.w.S 'et-hak.EliyM:: lO' yAda` haS.w.S 'ay.Eh hak.EliyM:: v:'Amar haS.w.S 'el-hag.:mal.iyM v:'el-hA'a:twOnwOt l:qaH:t.eM 'et-hak.EliyM. k.iy lO' 'Ahab 'et-hag.:mal.iyM v:'et-hA'a:twOnwOt:: gAn:bw. hag.:mal.iyM v:hA'a:twOnwOt 'et-hak.EliyM v:'Ak:lw. 'et-hap.:riy v:'et-hab.As,Ar v:'et-hal.eHeM k.iy 'Ah:bw. 'et-hA'Okel v:lO' 'Ah:bw. 'et-haS.w.S")
