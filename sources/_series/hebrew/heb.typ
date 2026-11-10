// heb.typ：希伯来语 DSL
//
//   #import "heb.typ": heb
//   #heb("hak.isE.'")     // → הַכִּסֵּא
//
// 语法是 LL(1) 的，每个字符就是一个 token。以逻辑顺序从左往右书写。
// 附标字符紧跟在字母后面，顺序任意，输出时根据 Unicode NFC 标准化。
// 
// holam: `O` 是普通 holam，在 waw 作 mater lectionis 时使用；
//        `;` 是 holam haser for vav，在 waw 本身是辅音的时候使用。
// 词边界由空格确定，`-` = maqaf (U+05BE)。
// 标点：
//   `-` = maqaf (U+05BE)。
//   `::` = sof pasuq（׃, U+05C3）
//   `..` = ASCII 句号
//   `,,` = ASCII 逗号
//   `;;` = ASCII 分号。
// 
// 转义：`_:` 是冒号, `__` 是下划线，`_{XXXX}` 是 Unicode 码点。

// ------------------------------------------------------------------ 码表 ---

// 辅音。
#let _letters = (
  " ": 0x20,  // Normal space
  "'": 0x5D0, // א aleph
  "b": 0x5D1, // ב bet/vet
  "g": 0x5D2, // ג gimel
  "d": 0x5D3, // ד dalet
  "h": 0x5D4, // ה he
  "w": 0x5D5, // ו vav
  "z": 0x5D6, // ז zayin
  "x": 0x5D7, // ח chet
  "T": 0x5D8, // ט tet
  "y": 0x5D9, // י yod
  "k": 0x5DB, // כ kaf/khaf
  "K": 0x5DA, // ך kaf 词尾形
  "l": 0x5DC, // ל lamed
  "m": 0x5DE, // מ mem
  "M": 0x5DD, // ם mem 词尾形（注意：fcitx5 那份码表漏了这个字母）
  "n": 0x5E0, // נ nun
  "N": 0x5DF, // ן nun 词尾形
  "S": 0x5E1, // ס samekh
  "`": 0x5E2, // ע ayin
  "p": 0x5E4, // פ pe/fe
  "P": 0x5E3, // ף pe 词尾形
  "c": 0x5E6, // צ tsadi
  "C": 0x5E5, // ץ tsadi 词尾形
  "q": 0x5E7, // ק qof
  "r": 0x5E8, // ר resh
  "s": 0x5E9, // ש shin（自动带 shin dot；再加 "," 就变成 sin）
  "t": 0x5EA, // ת tav
)

// 别名。
#let _aliases = (
  "\"": "`",  // ayin
  "H": "x",   // chet
  "j": "y",   // yod
  "v": "w",   // vav
  "V": "b",
  "f": "p",
  "F": "P",
)

// 附标。
#let _points = (
  ":": 0x5B0, // shewa ְ
  "a": 0x5B7, // patah ַ（短 a）
  "A": 0x5B8, // qamats ָ（长 a）
  "o": 0x5B8, // qamats qatan（读 /o/，字形和码点都是 qamats）
  "e": 0x5B6, // segol ֶ（短 e）
  "E": 0x5B5, // tsere ֵ（长 e）
  "i": 0x5B4, // hiriq ִ（长 i 再补一个 yod）
  "O": 0x5B9, // holam ֹ（长 o；跟在 w 后面时就是 holam male）
  ";": 0x5BA, // holam haser for vav ֺ（waw 作辅音 /wo/ 时的 holam，点偏左）
  "u": 0x5BB, // qubuts ֻ（短 u；长 u 是 shureq = "w."）
  ".": 0x5BC, // dagesh ּ（也包括 mapiq、shureq 里的那个点）
  ",": 0x5C2, // sin dot ׂ（只能跟在 s 后面）
)

// 名称，用于打印。
// Typst 的 dict 键只能是字符串，所以"码点 → 值"的表写成 pair 列表再折成 dict。
#let _map(pairs) = pairs.fold((:), (acc, p) => {
  acc.insert(str(p.at(0)), p.at(1))
  acc
})

#let _names = _map((
  (0x20, "普通空格"),
  (0x5D0, "aleph"), (0x5D1, "bet / vet"), (0x5D2, "gimel"), (0x5D3, "dalet"),
  (0x5D4, "he"), (0x5D5, "vav"), (0x5D6, "zayin"), (0x5D7, "chet"),
  (0x5D8, "tet"), (0x5D9, "yod"), (0x5DA, "kaf（词尾）"), (0x5DB, "kaf / khaf"),
  (0x5DC, "lamed"), (0x5DD, "mem（词尾）"), (0x5DE, "mem"), (0x5E0, "nun"),
  (0x5DF, "nun（词尾）"),
  (0x5E1, "samekh"), (0x5E2, "ayin"), (0x5E3, "pe（词尾）"), (0x5E4, "pe / fe"),
  (0x5E5, "tsadi（词尾）"), (0x5E6, "tsadi"), (0x5E7, "qof"), (0x5E8, "resh"),
  (0x5E9, "shin / sin"), (0x5EA, "tav"),
  (0x5B0, "shewa"), (0x5B1, "hataf segol"), (0x5B2, "hataf patah"),
  (0x5B3, "hataf qamats"), (0x5B4, "hiriq"), (0x5B5, "tsere"), (0x5B6, "segol"),
  (0x5B7, "patah"), (0x5B8, "qamats"), (0x5B9, "holam"),
  (0x5BA, "holam haser for vav"), (0x5BB, "qubuts"),
  (0x5BC, "dagesh"), (0x5C2, "sin dot"),
))

// 标点
#let _punct = (
  ("-", 0x5BE, "maqaf（希伯来连字符）"),
  ("::", 0x5C3, "sof pasuq（诗句结束）"),
  ("..", 0x2E, "句号"),
  (",,", 0x2C, "逗号"),
  (";;", 0x3B, "分号"),
  ("_:", 0x3A, "ASCII 冒号"),
  ("_-", 0x2D, "ASCII 连字符"),
  ("_{05C0}", 0x5C0, "paseq（分隔竖线）"),
)

// 附标字符 -> 双写之后得到的独立字符。
#let _doubles = _map(_punct.filter(p => {
  let code = p.at(0)
  let doubled = code.len() == 2 and code.at(0) == code.at(1)
  doubled and _points.at(code.at(0), default: none) != none
}).map(p => (p.at(0).at(0), p.at(1))))

// 希伯来区段里真正是组合记号的那些。maqaf（05BE）、paseq（05C0）、sof pasuq
// （05C3）、nun hafukha（05C6）虽然也是"标点"，但都不是组合记号。
#let _mark-ranges = ((0x591, 0x5BD), (0x5BF, 0x5C2), (0x5C4, 0x5C5))
#let _is-mark(cp) = _mark-ranges.any(r => r.at(0) <= cp and cp <= r.at(1)) or cp == 0x5C7

// 码点 → 至少四位的十六进制，给 `_{XXXX}` 转义用。
#let _hex4(cp) = {
  let s = upper(str(cp, base: 16))
  while s.len() < 4 { s = "0" + s }
  s
}

// 反表：码点（十进制字符串）→ 编码。encode() 和 heb-sheet() 用。
#let _rev-letters = _letters.pairs().fold((:), (acc, p) => {
  acc.insert(str(p.at(1)), p.at(0))
  acc
})

#let _rev-points = _points.pairs().fold((:), (acc, p) => {
  // "A" 和 "o" 都是 qamats，反表里留先出现的那个
  if acc.at(str(p.at(1)), default: none) == none {
    acc.insert(str(p.at(1)), p.at(0))
  }
  acc
})

// 反表：码点 → 标点编码。ASCII 冒号与 sof pasuq、ASCII 连字符与 maqaf 这类
// "同形不同码"的区分全靠这张表。
#let _rev-punct = _punct.fold((:), (acc, p) => {
  acc.insert(str(p.at(1)), p.at(0))
  acc
})

// ------------------------------------------------------------------ 内部 ---

// Unicode canonical combining class（只列希伯来附标；区段外一律当 0）。
// 记号段按它做稳定排序，得到的顺序就等于 NFC 的规范顺序——希伯来语没有
// 组合类分解，NFC 对它就只剩"按 ccc 排序"这一件事。
#let _ccc = _map((
  // 重音符（te'amim）。码表里还没有它们，但 `_{XXXX}` 转义已经能写出来，
  // 排序必须是对的（数值取自 UnicodeData.txt）。
  (0x591, 220), (0x592, 230), (0x593, 230), (0x594, 230), (0x595, 230),
  (0x596, 220), (0x597, 230), (0x598, 230), (0x599, 230), (0x59A, 222),
  (0x59B, 220), (0x59C, 230), (0x59D, 230), (0x59E, 230), (0x59F, 230),
  (0x5A0, 230), (0x5A1, 230), (0x5A2, 220), (0x5A3, 220), (0x5A4, 220),
  (0x5A5, 220), (0x5A6, 220), (0x5A7, 220), (0x5A8, 230), (0x5A9, 230),
  (0x5AA, 220), (0x5AB, 230), (0x5AC, 230), (0x5AD, 230), (0x5AE, 230),
  (0x5AF, 230),
  // 元音、shewa、各种点
  (0x5B0, 10), (0x5B1, 11), (0x5B2, 12), (0x5B3, 13), (0x5B4, 14),
  (0x5B5, 15), (0x5B6, 16), (0x5B7, 17), (0x5B8, 18), (0x5B9, 19),
  (0x5BA, 19), (0x5BB, 20), (0x5BC, 21), (0x5BD, 22), (0x5BF, 23),
  (0x5C1, 24), (0x5C2, 25), (0x5C4, 230), (0x5C5, 220), (0x5C7, 18),
))

#let _vowel-set = (0x5B4, 0x5B5, 0x5B6, 0x5B7, 0x5B8, 0x5B9, 0x5BA, 0x5BB)
#let _hataf-set = (0x5B1, 0x5B2, 0x5B3)
// 短元音 + shewa → 对应的 hataf（Unicode 里是三个独立码点，NFC 不会帮你合成）
#let _hataf-of = ((0x5B7, 0x5B2), (0x5B6, 0x5B1), (0x5B8, 0x5B3))
#let _shewa = 0x5B0
#let _dagesh = 0x5BC
#let _shin = 0x5E9
#let _shin-dot = 0x5C1
#let _sin-dot = 0x5C2
#let _maqaf = 0x5BE
#let _vav = 0x5D5
// holam male 与 vav haluma 的区别由**码点**表达，不靠字体去猜：普通 holam
// （U+05B9）压在 waw 的右半／正中，写辅音 waw 上的 holam haser 才是 U+05BA，
// 它保留 holam 的常规位置（字母左上）。所以这两个码点必须能分别写出来。
#let _holam-haser-vav = 0x5BA

// 报错。`ch` 是闯祸的那个字符（不用 src.slice：源串里现在可能有非 ASCII，
// 按字节切会切碎 UTF-8 序列）。
#let _fail(src, i, ch, msg) = panic(
  "heb: " + msg + "（第 " + str(i + 1) + " 个字符 " + repr(ch)
    + "，整个字符串 " + repr(src) + "）",
)

// `_` 转义：返回（码点, 下一个要处理的位置）。
//   `_x`     → x 的码点
//   `_{05C3}` → 十六进制码点（1–6 位）
#let _escape(chars, i, src) = {
  let n = chars.len()
  if i + 1 >= n {
    _fail(src, i, "_", "`_` 转义后面没有字符了")
  }
  let c = chars.at(i + 1)
  if c != "{" {
    (c.to-unicode(), i + 2)
  } else {
    let j = i + 2
    let hex = ""
    while j < n and chars.at(j) != "}" {
      hex += chars.at(j)
      j += 1
    }
    if j >= n {
      _fail(src, i, "_", "`_{` 没有闭合的 `}`")
    }
    if hex.len() == 0 or hex.len() > 6 {
      _fail(src, i, "_", "`_{...}` 里要写 1–6 位十六进制数字，现在是 " + repr(hex))
    }
    let digits = "0123456789abcdefABCDEF"
    for h in hex.codepoints() {
      if not digits.contains(h) {
        _fail(src, i, "_", "`_{...}` 里的 " + repr(h) + " 不是十六进制数字")
      }
    }
    let cp = int(hex, base: 16)
    if cp > 0x10FFFF or (0xD800 <= cp and cp <= 0xDFFF) {
      _fail(src, i, "_", "U+" + upper(hex) + " 不是合法码点")
    }
    (cp, j + 1)
  }
}

// 一个音节的收尾：补 shin dot、按规范排序，拼成字符串。
#let _syllable(letter, marks) = {
  let m = marks
  if letter == _shin {
    let sin = m.contains(_sin-dot)
    m = m.filter(x => x != _shin-dot and x != _sin-dot)
    m.push(if sin { _sin-dot } else { _shin-dot })
  }
  m = m.sorted(key: x => _ccc.at(str(x), default: 0))
  str.from-unicode(letter) + m.map(str.from-unicode).join()
}

// -------------------------------------------------------------- 解码/编码 ---

/// ASCII DSL → 希伯来文本（str；逻辑顺序，附标已按规范顺序排好）。
#let decode(src) = {
  if type(src) != str { panic("heb: 参数必须是字符串（是不是漏了引号？）") }

  let chars = src.codepoints()
  let n = chars.len()
  // 输出序列：音节 (letter:, marks:)，或者已定型的字符串 (raw:)：空格、maqaf、标点。
  let syllables = ()
  let letter = none
  let marks = ()

  let i = 0
  while i < n {
    let ch = chars.at(i)

    // ---- `_` 转义：把下一个字符（或 `{十六进制码点}`）按普通字符插进来 ----
    if ch == "_" {
      let (cp, next) = _escape(chars, i, src)
      if _is-mark(cp) {
        if letter == none {
          _fail(
            src, i, ch,
            "转义出来的附标（" + _names.at(str(cp), default: "U+" + _hex4(cp)) + "）前面没有字母",
          )
        }
        // 逃逸的附标不过 DSL 的合法性检查（后门的意义就在于此），但参与规范排序
        marks.push(cp)
      } else {
        if letter != none {
          syllables.push((letter: letter, marks: marks))
          letter = none
          marks = ()
        }
        if 0x5D0 <= cp and cp <= 0x5EA {
          // 是辅音就当一个新字母，后面写的附标还能挂上去
          letter = cp
        } else {
          syllables.push((raw: str.from-unicode(cp)))
        }
      }
      i = next
      continue
    }

    // ---- 双写：`::` / `..` / `,,` / `;;` 是同形状的独立标点 ----
    // 放在附标之前：附标字符单写时只能附在字母上，所以这一串在原语法里必是错误，
    // 双写不会抢走任何已有含义。
    if i + 1 < n and chars.at(i + 1) == ch and _doubles.at(ch, default: none) != none {
      if letter != none {
        syllables.push((letter: letter, marks: marks))
        letter = none
        marks = ()
      }
      syllables.push((raw: str.from-unicode(_doubles.at(ch))))
      i += 2
      continue
    }

    let code = _aliases.at(ch, default: ch)

    if code == " " or code == "-" {
      if letter != none {
        syllables.push((letter: letter, marks: marks))
        letter = none
        marks = ()
      }
      syllables.push((raw: if code == " " { " " } else { str.from-unicode(_maqaf) }))
      i += 1
      continue
    }

    if _letters.at(code, default: none) != none {
      if letter != none {
        syllables.push((letter: letter, marks: marks))
      }
      letter = _letters.at(code)
      marks = ()
      i += 1
      continue
    }

    let cp = _points.at(code, default: none)
    if cp == none {
      _fail(
        src, i, code,
        "未知编码（" + code + " 既不是字母也不是附标；要写 ASCII 标点请用 `_` 转义）",
      )
    }
    if letter == none {
      _fail(src, i, code, "附标前面没有字母")
    }

    if cp in _vowel-set {
      if marks.any(m => m in _vowel-set) {
        _fail(src, i, code, "一个字母上只能有一个元音")
      }
      if cp == _holam-haser-vav and letter != _vav {
        _fail(src, i, code, "holam haser for vav（\";\"）只能跟在 w 后面")
      }
      // "a:" 和 ":a" 都算 hataf：shewa 和短元音挨在一起就合并
      let pair = _hataf-of.find(p => p.at(0) == cp)
      if pair != none and marks.contains(_shewa) {
        marks = marks.filter(m => m != _shewa)
        marks.push(pair.at(1))
      } else {
        marks.push(cp)
      }
    } else if cp == _shewa {
      if marks.contains(_shewa) or marks.any(m => m in _hataf-set) {
        _fail(src, i, code, "重复的 shewa")
      }
      let pair = if marks.len() > 0 {
        _hataf-of.find(p => p.at(0) == marks.last())
      } else {
        none
      }
      if pair != none {
        marks = marks.slice(0, marks.len() - 1)
        marks.push(pair.at(1))
      } else {
        marks.push(cp)
      }
    } else if cp == _dagesh {
      if marks.contains(_dagesh) {
        _fail(src, i, code, "重复的 dagesh")
      }
      marks.push(cp)
    } else if cp == _sin-dot {
      if letter != _shin {
        _fail(src, i, code, "sin dot 只能跟在 s（ש）后面")
      }
      marks.push(cp)
    } else {
      marks.push(cp)
    }

    i += 1
  }

  if letter != none {
    syllables.push((letter: letter, marks: marks))
  }

  syllables
    .map(s => {
      if s.at("raw", default: none) != none { s.raw } else { _syllable(s.letter, s.marks) }
    })
    .join()
}

/// 希伯来文本 → ASCII DSL。给迁移旧文本用；码表里没有的码点写成 `_{XXXX}`
/// （所以 encode 的输出总能再 decode 回去）。
#let encode(src) = {
  let out = ""
  for ch in src.codepoints() {
    let cp = ch.to-unicode()
    if cp == 0x20 {
      out += " "
    } else if cp == _shin-dot {
      // shin dot 是 "s" 自带的，省略
    } else if _hataf-set.contains(cp) {
      let pair = _hataf-of.find(p => p.at(1) == cp)
      out += _rev-points.at(str(pair.at(0))) + ":"
    } else if _rev-letters.at(str(cp), default: none) != none {
      out += _rev-letters.at(str(cp))
    } else if _rev-points.at(str(cp), default: none) != none {
      out += _rev-points.at(str(cp))
    } else if _rev-punct.at(str(cp), default: none) != none {
      out += _rev-punct.at(str(cp))
    } else if cp == 0x5F {
      out += "__"
    } else {
      out += "_{" + _hex4(cp) + "}"
    }
  }
  out
}

// ---------------------------------------------------------------- 展示 ---

// 一个 RTL 文本片段。两个 target 走两条路，因为 typst 0.15 的 HTML 导出会**丢掉
// 所有 text() 的行内样式**（size / dir / lang / font 全都只剩文字，`align` /
// `block` / `grid` 更是连内容一起丢），只留下结构。所以：
//   · paged（PDF）    → text(dir: rtl, size: …)，正常排版
//   · html（博客）    → 直接吐一个 <span dir="rtl" style="font-size: …">
// 不这么写的话，网页里的希伯来语就只有正文字号，而且没有 RTL 隔离。
#let _run(body, size) = context {
  if target() == "html" {
    html.elem(
      "span",
      attrs: (class: "heb", dir: "rtl", lang: "he", style: "font-size: 1.45em"),
      body,
    )
  } else {
    text(dir: rtl, lang: "he", size: size, body)
  }
}

/// 夹在两段 RTL 之间的中性内容（箭头、破折号、括号…）必须显式标成 LTR。
///
/// HTML 的 `dir="rtl"` 等价于 `unicode-bidi: isolate`，所以 `<span dir="rtl">A</span>
/// ← <span dir="rtl">B</span>` 在网页上就是 README 里写的那个顺序。而 Typst 的
/// `text(dir: rtl)` 只把这一段标成 RTL、**不做隔离**，于是箭头这种中性字符会把
/// 左右两段并成一个 RTL run，整行跟着镜像：源码写 `A ← B`，PDF 印出来是 `B ← A`。
/// 包一层 LRM（U+200E）把这个中性串夹在两个强 LTR 字符之间即可。
///
/// 换用 RLI … PDI 把每段 RTL 都隔离起来看似更彻底，但对一段只含希伯来语的
/// 段落（也就是「例文」那种）会弄丢段落级的 RTL 信号：隔离对象在双向算法里是
/// 中性的，整个段落就回落成 LTR，不再右对齐。
#let ltr-island(body) = context {
  if target() == "html" { body } else { [#str.from-unicode(0x200E)#body#str.from-unicode(0x200E)] }
}

/// 行内希伯来语。`size` 相对正文（希伯来字母视觉上比汉字小，放大一点）。
#let heb(src, size: 1.7em) = _run(decode(src), size)

// -------------------------------------------------------------- 速查表 ---

/// 码表 → 表格，直接从 _letters / _points 生成，不会和解析器脱节。
#let heb-sheet() = {
  // 光秃秃的组合记号不好看，给它挂个"宿主"字母：元音挂在 א 上，各种点挂在
  // 真正带它的字母上（dagesh → ב、sin dot → ש、haser for vav → ו）。
  let carrier(cp) = {
    let base = if cp == _sin-dot or cp == _shin-dot {
      0x5E9
    } else if cp == _dagesh {
      0x5D1
    } else if cp == _holam-haser-vav {
      _vav
    } else {
      0x5D0
    }
    _run(str.from-unicode(base) + str.from-unicode(cp), 1.6em)
  }
  let letters = _letters.pairs().map(p => (p.at(0), p.at(1)))
  // 附标列表 = _points 去重 + 三个 hataf（由短元音 + ":" 合成，所以不是独立编码）
  let points = _points.pairs().fold((), (acc, p) => {
    if acc.any(q => q.at(1) == p.at(1)) { acc } else { acc.push(p); acc }
  })
  points = points.map(p => (p.at(0), p.at(1)))
  points += _hataf-of.map(p => (_rev-points.at(str(p.at(0))) + ":", p.at(1)))
  let rows = calc.max(letters.len(), points.len())
  let main = table(
    columns: (auto, auto, 1fr, auto, auto, 1fr),
    inset: (x: 6pt, y: 3pt),
    stroke: 0.4pt + luma(190),
    align: center + horizon,
    ..("编码", "字母", "名称", "编码", "附标", "名称"),
    ..range(rows).map(r => {
      let row = ()
      if r < letters.len() {
        row += (
          raw(letters.at(r).at(0)),
          _run(str.from-unicode(letters.at(r).at(1)), 1.4em),
          _names.at(str(letters.at(r).at(1))),
        )
      } else {
        row += ("", "", "")
      }
      if r < points.len() {
        row += (
          raw(points.at(r).at(0)),
          carrier(points.at(r).at(1)),
          _names.at(str(points.at(r).at(1)), default: ""),
        )
      } else {
        row += ("", "", "")
      }
      row
    }).flatten(),
  )

  // 标点表。就从 _punct 生成：单写就能用的只有 maqaf（`-`）——它本来就是独立
  // 字符，所以不参与双写；其余条目要么双写（`::` `..` `,,` `;;`），要么 `_` 转义。
  let punct-rows = calc.div-euclid(_punct.len() + 1, 2)
  let punct-table = table(
    columns: (auto, auto, 1fr, auto, auto, 1fr),
    inset: (x: 6pt, y: 3pt),
    stroke: 0.4pt + luma(190),
    align: center + horizon,
    ..("编码", "字符", "名称", "编码", "字符", "名称"),
    ..range(punct-rows).map(r => {
      let cells = ()
      for k in (2 * r, 2 * r + 1) {
        if k < _punct.len() {
          let p = _punct.at(k)
          cells += (raw(p.at(0)), _run(str.from-unicode(p.at(1)), 1.4em), p.at(2))
        } else {
          cells += ("", "", "")
        }
      }
      cells
    }).flatten(),
  )

  // 拼接而不是 stack/grid：HTML 导出会连内容一起丢掉 stack，table 则会保留。
  main + text(weight: "bold")[标点] + punct-table
}

#let large-arrow = [#set text(size: 18pt); #ltr-island[$<-$]]
