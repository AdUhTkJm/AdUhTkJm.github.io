#import "@preview/cuti:0.4.0"
#set document(title: "Dies Irae")
#set page(paper: "a4", margin: 2.3cm)
#set text(size: 10.5pt, font: ("Libertinus Serif", "Noto Serif CJK SC"))
#set heading(numbering: "1.1")
#show link: underline

#let glosses = (
  saeclum: (lemma: [saeculum, -ī], pos: "[n.]", meaning: [时代。]),
  favilla: (lemma: [favilla, -ae], pos: "[f.]", meaning: [灰烬；余烬。]),
  testis: (lemma: [testis, -is], pos: "[m/f.]", meaning: [证明。]),
  solvo: (lemma: [solvo, -ere, solvi, solutum], pos: "[v.]", meaning: [解开，溶解，瓦解。]),
  judex: (lemma: [judex, -icis], pos: "[m.]", meaning: [审判者；法官。]),
  cunctus: (lemma: [cunctus, -a, -um], pos: "[a.]", meaning: [全部。]),
  tuba: (lemma: [tuba, -ae], pos: "[f.]", meaning: [号角，喇叭。]),
  spargo: (lemma: [spargo, -ere, sparsi, sparsum], pos: "[v.]", meaning: [散布，撒播。]),
  sonus: (lemma: [sonus, -ī], pos: "[m.]", meaning: [声音。]),
  sepulcrum: (lemma: [sepulcrum, -ī], pos: "[n.]", meaning: [坟墓。]),
  regio: (lemma: [regio, -ionis], pos: "[f.]", meaning: [地区，区域。]),
  cogo: (lemma: [cogo, -ere, coegi, coactum], pos: "[v.]", meaning: [聚集；强迫。]),
  thronus: (lemma: [thronus, -ī], pos: "[m.]", meaning: [宝座，王座。]),
  mors: (lemma: [mors, mortis], pos: "[f.]", meaning: [死亡。]),
  stupeo: (lemma: [stupeo, -ēre, stupui], pos: "[v.]", meaning: [惊愕，发呆。]),
  natura: (lemma: [natura, -ae], pos: "[f.]", meaning: [自然，本性。]),
  resurgo: (lemma: [resurgo, -ere, -surrexi, -surrectum], pos: "[v.]", meaning: [再起，复活。]),
  creatura: (lemma: [creatura, -ae], pos: "[f.]", meaning: [受造物，生灵。]),
  liber: (lemma: [liber, libri], pos: "[m.]", meaning: [书。]),
  profero: (lemma: [profero, -ferre, protuli, prolatum], pos: "[v.]", meaning: [拿出，呈上。]),
  contineo: (lemma: [contineo, -ēre, continui, contentum], pos: "[v.]", meaning: [包含，记载。]),
  mundus: (lemma: [mundus, -ī], pos: "[m.]", meaning: [世界。]),
  judico: (lemma: [judico, -are], pos: "[v.]", meaning: [审判，裁决。]),
  lateo: (lemma: [lateo, -ēre, latui], pos: "[v.]", meaning: [隐藏，潜伏。]),
  appareo: (lemma: [appareo, -ēre, apparui], pos: "[v.]", meaning: [显现，出现。]),
  inultus: (lemma: [inultus, -a, -um], pos: "[a.]", meaning: [未受惩罚的，未复仇的。]),
  remaneo: (lemma: [remaneo, -ēre, remansi], pos: "[v.]", meaning: [留下，残留。]),
  sedeo: (lemma: [sedeo, -ēre, sedi, sessum], pos: "[v.]", meaning: [坐。]),
  miser: (lemma: [miser, -a, -um], pos: "[a.]", meaning: [可怜的，悲惨的。]),
  patronus: (lemma: [patronus, -ī], pos: "[m.]", meaning: [保护人，辩护人。]),
  vix: (lemma: [vix], pos: "[adv.]", meaning: [几乎不，勉强。]),
  securus: (lemma: [securus, -a, -um], pos: "[a.]", meaning: [安全的，无忧的。]),
  rex: (lemma: [rex, regis], pos: "[m.]", meaning: [王。]),
  tremendus: (lemma: [tremendus, -a, -um], pos: "[a.]", meaning: [可畏的，可怕的。]),
  majestas: (lemma: [majestas, -atis], pos: "[f.]", meaning: [威严，尊荣。]),
  salvo: (lemma: [salvo, -are], pos: "[v.]", meaning: [拯救。]),
  gratis: (lemma: [gratis], pos: "[adv.]", meaning: [无偿地，白白地。]),
  fons: (lemma: [fons, fontis], pos: "[m.]", meaning: [泉，泉源。]),
  pietas: (lemma: [pietas, -atis], pos: "[f.]", meaning: [虔诚；仁慈，怜悯。]),
  recordor: (lemma: [recordor, -ari], pos: "[v.]", meaning: [记得，回想。]),
  pius: (lemma: [pius, -a, -um], pos: "[a.]", meaning: [虔诚的，仁慈的。]),
  causa: (lemma: [causa, -ae], pos: "[f.]", meaning: [原因，缘故。]),
  tuus: (lemma: [tuus, -a, -um], pos: "[pron.]", meaning: [你的。]),
  via: (lemma: [via, -ae], pos: "[f.]", meaning: [道路，旅程。]),
  perdo: (lemma: [perdo, -ere, perdidi, perditum], pos: "[v.]", meaning: [毁灭，丧失。]),
  dies: (lemma: [dies, -ei], pos: "[m.]", meaning: [日，天。]),
  quaero: (lemma: [quaero, -ere, quaesivi, quaesitum], pos: "[v.]", meaning: [寻找。]),
  lassus: (lemma: [lassus, -a, -um], pos: "[a.]", meaning: [疲倦的。]),
  redimo: (lemma: [redimo, -ere, redemi, redemptum], pos: "[v.]", meaning: [赎回，救赎。]),
  crux: (lemma: [crux, crucis], pos: "[f.]", meaning: [十字架。]),
  labor: (lemma: [labor, -oris], pos: "[m.]", meaning: [辛劳，劳动。]),
  cassus: (lemma: [cassus, -a, -um], pos: "[a.]", meaning: [空的，徒劳的。]),
  ultio: (lemma: [ultio, -ionis], pos: "[f.]", meaning: [报复，惩罚。]),
  donum: (lemma: [donum, -ī], pos: "[n.]", meaning: [礼物，恩赐。]),
  remissio: (lemma: [remissio, -ionis], pos: "[f.]", meaning: [宽恕，赦免。]),
  ratio: (lemma: [ratio, -ionis], pos: "[f.]", meaning: [计算，清算；理智。]),
  ingemisco: (lemma: [ingemisco, -ere], pos: "[v.]", meaning: [叹息，呻吟。]),
  reus: (lemma: [reus, -ī], pos: "[m.]", meaning: [被告；罪人。]),
  culpa: (lemma: [culpa, -ae], pos: "[f.]", meaning: [罪过，过失。]),
  rubeo: (lemma: [rubeo, -ēre], pos: "[v.]", meaning: [发红，羞红。]),
  vultus: (lemma: [vultus, -us], pos: "[m.]", meaning: [面容，脸。]),
  supplico: (lemma: [supplico, -are], pos: "[v.]", meaning: [恳求。]),
  parco: (lemma: [parco, -ere, peperci, parsum], pos: "[v.]", meaning: [宽恕，饶恕（后接与格）。]),
  mariam: (lemma: [Maria, -ae], pos: "[f.]", meaning: [马利亚。]),
  absolvo: (lemma: [absolvo, -ere, absolvi, absolutum], pos: "[v.]", meaning: [赦免，宣告无罪。]),
  latro: (lemma: [latro, -onis], pos: "[m.]", meaning: [强盗，盗贼。]),
  exaudio: (lemma: [exaudio, -ire, exaudivi, exauditum], pos: "[v.]", meaning: [垂听，应允。]),
  quoque: (lemma: [quoque], pos: "[adv.]", meaning: [也，同样（通常后置）。]),
  spes: (lemma: [spes, -ei], pos: "[f.]", meaning: [希望。]),
  do: (lemma: [do, dare, dedi, datum], pos: "[v.]", meaning: [给予。]),
  prex: (lemma: [prex, precis], pos: "[f.]", meaning: [祈祷（复数 preces 更常用）。]),
  dignus: (lemma: [dignus, -a, -um], pos: "[a.]", meaning: [值得的，相称的。]),
  benigne: (lemma: [benigne], pos: "[adv.]", meaning: [仁慈地，和善地。]),
  perennis: (lemma: [perennis, -e], pos: "[a.]", meaning: [永恒的，不灭的。]),
  cremo: (lemma: [cremo, -are], pos: "[v.]", meaning: [焚烧。]),
  ignis: (lemma: [ignis, -is], pos: "[m.]", meaning: [火。]),
  ovis: (lemma: [ovis, -is], pos: "[f.]", meaning: [绵羊。]),
  locus: (lemma: [locus, -ī], pos: "[m.]", meaning: [地方，位置。]),
  praesto: (lemma: [praesto, -are], pos: "[v.]", meaning: [给予，提供。]),
  haedus: (lemma: [haedus, -ī], pos: "[m.]", meaning: [山羊。]),
  sequestro: (lemma: [sequestro, -are], pos: "[v.]", meaning: [使分离，隔开。]),
  statuo: (lemma: [statuo, -ere, statui, statutum], pos: "[v.]", meaning: [安置，使站立。]),
  pars: (lemma: [pars, partis], pos: "[f.]", meaning: [部分，一边。]),
  dexter: (lemma: [dexter, -tra, -trum], pos: "[a.]", meaning: [右边的。]),
  confuto: (lemma: [confuto, -are], pos: "[v.]", meaning: [驳倒，使羞愧。]),
  maledictus: (lemma: [maledictus, -a, -um], pos: "[a.]", meaning: [被诅咒的，恶人。]),
  flamma: (lemma: [flamma, -ae], pos: "[f.]", meaning: [火焰。]),
  acer: (lemma: [acer, acris, acre], pos: "[a.]", meaning: [猛烈的，尖锐的。]),
  addico: (lemma: [addico, -ere, addixi, addictum], pos: "[v.]", meaning: [判决给，交付。]),
  voco: (lemma: [voco, -are], pos: "[v.]", meaning: [呼唤，召唤。]),
  benedictus: (lemma: [benedictus, -a, -um], pos: "[a.]", meaning: [蒙福的，受祝福的。]),
  oro: (lemma: [oro, -are], pos: "[v.]", meaning: [祈求，恳求。]),
  supplex: (lemma: [supplex, -icis], pos: "[a.]", meaning: [恳求的，跪拜的。]),
  acclinis: (lemma: [acclinis, -e], pos: "[a.]", meaning: [倾身的，俯伏的。]),
  contritus: (lemma: [contritus, -a, -um], pos: "[a.]", meaning: [破碎的，痛悔的。]),
  cinis: (lemma: [cinis, -eris], pos: "[m.]", meaning: [灰烬。]),
  gero: (lemma: [gero, -ere, gessi, gestum], pos: "[v.]", meaning: [从事，承担。]),
  cura: (lemma: [cura, -ae], pos: "[f.]", meaning: [关心，照料。]),
  finis: (lemma: [finis, -is], pos: "[m.]", meaning: [终点，结局。]),
  lacrimosus: (lemma: [lacrimosus, -a, -um], pos: "[a.]", meaning: [流泪的，悲伤的。]),
  homo: (lemma: [homo, -inis], pos: "[m.]", meaning: [人。]),
  hic: (lemma: [hic, haec, hoc], pos: "[pron.]", meaning: [这个。]),
  eis: (lemma: [is, ea, id], pos: "[pron.]", meaning: [他/她/它；这个。]),
  dono: (lemma: [dono, -are], pos: "[v.]", meaning: [给予，赐予。]),
  requies: (lemma: [requies, -ei], pos: "[f.]", meaning: [安息，休息。]),
)

// 全局编号。
#let numbers = state("num", ())
#let assign(key) = numbers.update(a => if key in a { a } else { a + (key,) })
#let number-of(key) = {
  let p = numbers.final().position(x => x == key)
  if p == none { none } else { p + 1 }
}

// 正文中的词汇，在 HTML 下是 <a class="term">词<sup>号</sup></a>。
// 变形词用 key 指向本体，例如 #term("solvet", key: "solvo")。
#let term(word, key: none) = {
  let k = if key == none { word } else { key }
  context {
    let n = number-of(k)
    if target() == "html" {
      html.elem(
        "a",
        attrs: (class: "term", href: "#glossary-" + k, "data-term": k),
        if n == none { word } else { [ #word#html.elem("sup", attrs: (class: "tn"), str(n)) ] },
      )
    } else {
      if n == none { word } else { [#word#super(str(n))] }
    }
  }
}

// 词义注释。
#let vnote(key) = {
  assign(key)
  context {
    let n = number-of(key)
    let e = glosses.at(key)
    let pos = e.at("pos", default: none)
    if target() == "html" {
      html.elem("li", attrs: (id: "glossary-" + key, "data-term": key), [
        #html.elem("span", attrs: (class: "n"), str(n))
        #html.elem("dfn", e.lemma)#if pos != none [ #pos]#" — "#e.meaning
      ])
    } else {
      [#n. #e.lemma #if pos != none [#set text(fill: gray); #pos ]— #e.meaning]
    }
  }
}

// 手写的语法注释。
#let gnote(key, body) = {
  assign(key)
  context {
    let n = number-of(key)
    if target() == "html" {
      html.elem("li", attrs: (id: "glossary-" + key, "data-term": key), [
        #html.elem("span", attrs: (class: "n"), str(n))#body
      ])
    } else {
      [#n. #body]
    }
  }
}

// 小节，也就是三行原文 + 注释。`notes` 的顺序决定编号顺序，请按原文阅读顺序排列。
#let stanza(latin, notes: ()) = context {
  let annot = if notes.len() > 0 {
    if target() == "html" {
      html.elem("ol", attrs: (class: "notes"), {
        for n in notes { n }
      })
    } else {
      list(marker: [], ..notes)
    }
  }
  if target() == "html" {
    html.elem("div", attrs: (class: "stanza"), [
      #html.elem("div", attrs: (class: "latin"), latin)
      #html.elem("div", attrs: (class: "annot"), annot)
    ])
  } else {
    grid(
      columns: if notes.len() > 0 { (1.05fr, 1fr) } else { 1fr },
      column-gutter: 1.6em,
      align: (left, top),
      latin,
      annot,
    )
  }
}

// 文末词表。
#let glossary() = context {
  let keys = numbers.final().filter(k => k in glosses)
  if target() == "html" {
    html.elem("dl", attrs: (class: "glossary"), for k in keys {
      let e = glosses.at(k)
      let pos = e.at("pos", default: none)
      html.elem("div", attrs: (class: "gloss"), [
        #html.elem("dt", [
          #html.elem("dfn", e.lemma)#if pos != none [ #pos]
        ])
        #html.elem("dd", e.meaning)
      ])
    })
  } else {
    for k in keys {
      let e = glosses.at(k)
      let pos = e.at("pos", default: none)
      block[#e.lemma#if pos != none [#set text(fill: gray); #pos] — #e.meaning]
    }
  }
}

= 简介

最近在玩 _Dies irae_ 这个游戏。这是个视觉小说，里面含有不少拉丁语和德语咏唱（足够中二，我喜欢）。

不过既然都开始咏唱了，总得知道它具体在说些什么。游戏不加解释地引用了《末日经》原文，毕竟这个东西的拉丁语标题就是 _dies irae_。所以下面就来分析一下它到底是什么意思。

= Dies Irae

#stanza(
  [Dies irae, dies illa \
   #term("solvet", key: "solvo") #term("saeclum") in #term("favilla"): \
   #term("teste", key: "testis") David cum Sibylla.],
  notes: (
    vnote("solvo"),
    vnote("saeclum"),
    vnote("favilla"),
    vnote("testis")
  ),
)

#stanza(
  [Quantus tremor #term("est futurus", key: "est-futurus"), \
   quando #term("judex") est venturus, \
   #term("cuncta", key: "cunctus") stricte discussurus!],
  notes: (
    gnote("est-futurus")[
      est futurus 类似英语的 _about to be_。和 erit 的区别在于有一种“即将到来的感觉”。
    ],
    vnote("judex"),
    vnote("cunctus"),
  ),
)

#stanza(
  [#term("Tuba", key: "tuba") mirum #term("spargens", key: "spargo") #term("sonum", key: "sonus") \
   per #term("sepulcra", key: "sepulcrum") regionum, \
   #term("coget", key: "cogo") omnes #term("ante", key: "per-ante") #term("thronum", key: "thronus").],
  notes: (
    vnote("tuba"),
    vnote("spargo"),
    vnote("sepulcrum"),
    vnote("cogo"),
    gnote("per-ante")[
      per 与 ante 都接宾格。
    ],
    vnote("thronus"),
  ),
)

#stanza(
  [Mors #term("stupebit", key: "stupeo") et natura, \
   cum #term("resurget", key: "resurgo") creatura, \
   #term("judicanti") responsura.],
  notes: (
    vnote("stupeo"),
    vnote("resurgo"),
    gnote("judicanti")[
      judicanti 是 _judicare_（审判）的现在分词，这里是与格。第三变格的形容词喜欢使用 -i 作为离格，而名词使用 -e。
    ],
  ),
)

#stanza(
  [Liber scriptus #term("proferetur", key: "profero"), \
   in quo totum #term("continetur", key: "contineo"), \
   unde mundus judicetur.],
  notes: (
    vnote("profero"),
    vnote("contineo"),
    gnote("unde-judicetur")[
      unde（由此）引导目的状语从句，因此 _judicetur_ 是虚拟式。
    ],
  ),
)

#stanza(
  [Judex ergo #term("cum", key: "cum-sedebit") sedebit, \
   quidquid #term("latet", key: "lateo") #term("apparebit", key: "appareo"): \
   nil #term("inultum", key: "inultus") remanebit.],
  notes: (
    gnote("cum-sedebit")[
      _cum_ 这里是“当……时”
    ],
    vnote("lateo"),
    vnote("appareo"),
    vnote("inultus"),
  ),
)

#stanza(
  [Quid sum miser tunc dicturus? \
   Quem #term("patronum", key: "patronus") rogaturus, \
   #term("cum", key: "cum-vix-justus") #term("vix") justus sit securus?],
  notes: (
    vnote("patronus"),
    gnote("cum-vix-justus")[
      这里的 _cum_ 是“既然”，引导让步从句。
    ],
    vnote("vix"),
  ),
)

#stanza(
  [Rex #term("tremendae", key: "tremendus") #term("majestatis", key: "majestas"), \
   qui #term("salvandos") salvas #term("gratis"), \
   salva me #term("fons", key: "fons") #term("pietatis", key: "pietas").],
  notes: (
    vnote("tremendus"),
    vnote("majestas"),
    gnote("salvandos")[
      这里是动形词，以动词的 -nd- 形态作为形容词，意为“应该”。
    ],
    vnote("gratis"),
    vnote("fons"),
    vnote("pietas"),
  ),
)

#stanza(
  [#term("Recordare", key: "recordor"), Jesu #term("pie", key: "pius"), \
   quod sum causa tuae viae: \
   #term("ne", key: "ne-perdas") me #term("perdas", key: "perdo") illa #term("die", key: "illa-die").],
  notes: (
    vnote("recordor"),
    vnote("pius"),
    vnote("perdo"),
    gnote("ne-perdas")[
      ne + 虚拟式表示否定祈使（“请不要……”）。
    ],
    gnote("illa-die")[
      _illa die_ 是时间夺格，“在那一天”；_illa_ 是指示代词，_die_ 是 _dies_ 的夺格。
    ],
  ),
)

#stanza(
  [Quaerens me, sedisti #term("lassus"): \
   #term("redemisti", key: "redimo") #term("Crucem", key: "crux") #term("passus"): \
   tantus labor non sit #term("cassus").],
  notes: (
    vnote("lassus"),
    vnote("redimo"),
    vnote("crux"),
    gnote("passus")[
      _passus_ 是 _patior_（忍受）的完成分词。这是个异位动词。
    ],
    vnote("cassus"),
    gnote("non-sit-cassus")[
      _non sit cassus_：否定祈愿式虚拟，“愿这辛劳不至白费”。
    ],
  ),
)

#stanza(
  [#term("Juste", key: "juste") judex #term("ultionis", key: "ultio"), \
   donum fac #term("remissionis", key: "remissio") \
   ante diem #term("rationis", key: "ratio").],
  notes: (
    gnote("juste")[
      _Juste_ 是 _justus_（公正的）的呼格，而非副词。
    ],
    vnote("ultio"),
    vnote("remissio"),
    vnote("ratio"),
  ),
)

#stanza(
  [#term("Ingemisco", key: "ingemisco"), tamquam #term("reus", key: "reus"): \
   culpa #term("rubet", key: "rubeo") #term("vultus", key: "vultus") meus: \
   #term("supplicanti", key: "supplico") #term("parce", key: "parco"), Deus.],
  notes: (
    vnote("ingemisco"),
    vnote("reus"),
    vnote("rubeo"),
    vnote("vultus"),
    vnote("supplico"),
    vnote("parco"),
    gnote("parce-dative")[
      parce 是命令式。它支配与格，故此处为 _supplicanti_。
    ],
  ),
)

#stanza(
  [Qui Mariam #term("absolvisti", key: "absolvo"), \
   et #term("latronem", key: "latro") #term("exaudisti", key: "exaudio"), \
   mihi quoque spem #term("dedisti", key: "do").],
  notes: (
    vnote("absolvo"),
    vnote("latro"),
    vnote("exaudio"),
    vnote("do"),
  ),
)

#stanza(
  [#term("Preces", key: "prex") meae non sunt dignae: \
   sed tu bonus fac #term("benigne"), \
   #term("ne", key: "ne-cremer") #term("perenni", key: "perennis") #term("cremer", key: "cremo") #term("igne", key: "igne").],
  notes: (
    vnote("prex"),
    vnote("benigne"),
    vnote("perennis"),
    vnote("cremo"),
    gnote("ne-cremer")[
      ne 加虚拟式表示否定目的，“以免我被焚烧”；
    ],
    gnote("igne")[
      igne 是工具夺格。
    ],
  ),
)

#stanza(
  [Inter #term("oves", key: "ovis") locum #term("praesta", key: "praesto"), \
   et ab #term("haedis", key: "haedus") me #term("sequestra", key: "sequestro"), \
   #term("statuens", key: "statuo") in parte dextra.],
  notes: (
    vnote("ovis"),
    vnote("praesto"),
    vnote("haedus"),
    vnote("sequestro"),
    vnote("statuo"),
  ),
)

#stanza(
  [#term("Confutatis", key: "confuto") maledictis, \
   flammis acribus #term("addictis", key: "addico"): \
   voca me cum benedictis.],
  notes: (
    vnote("confuto"),
    vnote("addico"),
  ),
)

#stanza(
  [#term("Oro", key: "oro") #term("supplex", key: "supplex") et #term("acclinis", key: "acclinis"), \
   cor #term("contritum", key: "contritus") quasi #term("cinis", key: "cinis"): \
   #term("gere", key: "gero") #term("", key: "gere-curam") curam mei finis.],
  notes: (
    vnote("oro"),
    vnote("supplex"),
    vnote("acclinis"),
    vnote("contritus"),
    vnote("cinis"),
    vnote("gero"),
    gnote("gere-curam")[
      此处为命令式。
    ],
  ),
)

#stanza(
  [Lacrimosa dies illa, \
   qua resurget ex favilla \
   judicandus homo #term("reus").],
  notes: (
  ),
)

#stanza(
  [#term("Huic", key: "huic-dative") ergo parce, Deus: \
   pie Jesu Domine, \
   dona eis requirem. Amen.],
  notes: (
    gnote("huic-dative")[
      指代上文 judicandus homo reus。被 parcere 支配，所以是与格。
    ],
  ),
)

= 词汇表

#glossary()
