#import "@preview/cuti:0.4.0"
#set document(title: "翠玉录")
#set page(paper: "a4", margin: 2.3cm)
#set text(size: 10.5pt, font: ("Libertinus Serif", "Noto Serif CJK SC"))
#set heading(numbering: "1.1")
#show link: underline

#let glosses = (
  mendacio: (lemma: [mendacio, -onis], pos: "[f.]", meaning: [谎言]),
  perpetro: (lemma: [perpetro, -are, -avi, -atus], pos: "[v.]", meaning: [完成，生效]),
  venter: (lemma: [venter, -tris], pos: "[m.]", meaning: [肚子，躯干；子宫]),
  nutrix: (lemma: [nutrix, -icis], pos: "[f.]", meaning: [乳母；泛指可以提供滋养的一切事物]),
  subtilis: (lemma: [subtilis, -e], pos: "[a.]", meaning: [精细；精准]),
  spissus: (lemma: [spissus, -a, -um], pos: "[a.]", meaning: [浓稠，厚重；缓慢，困难]),
  ideo: (lemma: [ideo], pos: "[adv.]", meaning: [因此。来自 id + eo]),
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

// 小节。这次一个句子就是一个小节。
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


和上一篇文章一样，这依然是 _Dies irae_ 这个视觉小说引用的一段文本。不过其实拉丁语有数个版本，有一部分还有中世纪的特有拼写（例如 totius 变成 tocius, -ae 变成 -e 之类的）。这里用的是拼法比较古典的版本。

#stanza(
  [Verum sine #term("mendacio"), certum, et verissimum.], notes: (
    vnote("mendacio"),
  )
)

#stanza(
  [Quod est inferius, est sicut quod est superius#term("", key: "as-above-so-below").], notes: (
    gnote("as-above-so-below")[赫尔墨斯学派认为“上”是大宇宙，指天体、自然，而“下”是小宇宙，指人类自身的精神。这两句话就是在说它们具有相同的运转规律。],
  )
)

#stanza(
  [Et quod est superius, est sicut quod est inferius, ad #term("perpetranda", key: "perpetro") miracula rei unius.], notes: (
    vnote("perpetro"),
  )
)

#stanza(
  [Et sicut res omnes fuerunt ab uno, meditatione unius,\
  sic omnes res natae ab hac una re, adaptatione.]
)

#stanza([
  Pater eius est Sol, mater eius est Luna.
])

#stanza([Portavit illud ventus in #term("ventre", key: "venter") suo.], notes: (
  vnote("venter"),
))

#stanza([#term("Nutrix", key: "nutrix") eius terra est.], notes: (
  vnote("nutrix"),
))

#stanza([
  Pater omnis #term("telesmi", key: "about-telesmi") totius mundi est hic.
], notes: (
  gnote("about-telesmi")[这里 telesmi 似乎是对阿拉伯语原文的转写，本意为“护身符”。],
))

#stanza([
  Vis eius integra est, si versa fuerit in terram.#term("", key: "sentence-split")
  Separabis terram ab igne, #term("subtile", key: "subtilis") ab #term("spisso", key: "spissus"),\
  suaviter cum magno ingenio.
], notes: (
  gnote("sentence-split")[有的版本会将 si versa... 作为下一句的开头。],
  vnote("subtilis"),
  vnote("spissus"),
))

#stanza([
  Ascendit a terra in #term("coelum"),\
  iterumque descendit in terram,\
  et recipit vim #term("superiorum") et inferiorum.
], notes: (
  gnote("coelum")[即 caelum，天空],
  gnote("superiorum")[这里其实是名词的复数属格形态。如果是比较级的话，是不会有 -um 后缀的。所以是“上面与下面的力量”。]
))

#stanza([
  Sic #term("habebis") gloriam totius mundi.
], notes: (
  gnote("habebis")[作者开始打广告：“信了这个，你就会……”],
))

#stanza([
  #term("Ideo", key: "ideo") fugiet a te omnis obscuritas.
], notes: (
  vnote("ideo"),
))

#stanza([
  Haec est totius fortitudinis fortitudo fortis,\
  quia vincet omnem rem subtilem,\
  omnemque solidam penetrabit.
])

#stanza([
  Sic mundus creatus est.
])

#stanza([
  Hinc erunt adaptationes mirabiles,\
quarum modus hic est.
])

#stanza([
  Itaque vocatus sum Hermes #term("Trismegistus"),\
  habens tres partes philosophiae#term("", key: "tres-philosophiae") totius mundi.
], notes: (
  gnote("Trismegistus")[意为“三重伟大”。],
  gnote("tres-philosophiae")[一般认为是炼金术、占星术与神通术。],
))

#stanza([
  Completum est, quod dixi de operatione Solis#term("", key: "opere-solis").
], notes: (
  gnote("opere-solis")[这里的太阳在炼金术词汇中一般代指贤者之石。所以 opere solis 其实是炼制贤者之石的工作，也就是 _magnum opus_。],
))

这似乎是中世纪炼金术士必备之作，在炼金术中的地位基本上相当于《道德经》在炼丹术中的地位。不过它没教你怎么炼金，基本上是总纲型的东西。
