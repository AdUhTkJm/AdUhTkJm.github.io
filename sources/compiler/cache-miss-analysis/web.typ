// Entry point for the web release of the dissertation (chapters 2-4 only).
//
// `dissertation.typ` is the submitted document: title page, declaration,
// proforma, outline, appendices, project proposal images. None of that belongs
// on a blog page, so this file picks the three chapters that carry the actual
// content and gives them their original numbers (Preparation is "2.").
//
// Cross-references are the reason this has to be one root file: chapter 2 links
// into @barvinok-impl and @eval, and @eval only exists as a label on the
// top-level heading `= Evaluation`, so it is declared here rather than in
// chapters/evaluation.typ. Compiling the chapters separately would leave those
// references dangling.
//
// The MLIR colouring rules below are copied from dissertation.typ rather than
// imported, because dissertation.typ is the whole document. The duplication only
// pays off in the PDF: typst's HTML exporter drops text fills, so on the web page
// these 23 snippets stay plain monospace (see src/styles/note.css for the same
// limitation worked around with semantic classes).

#set document(title: "以多面体方法分析缓存未命中数")
#set heading(numbering: "1.")
#set document(title: "bv_decide 的位爆破")
#set page(paper: "a4", margin: 2.3cm)
#set text(size: 10.5pt, font: ("Libertinus Serif", "Noto Serif CJK SC"))

#show raw.where(lang: "mlir"): it => {
  // %name: purple
  show regex("%[\w\d._]+"): set text(fill: rgb("#AF00DB"))
  // #attr: orange
  show regex("#[\w\d._]+"): set text(fill: orange)
  // !type: blue
  show regex("![\w\d._]+"): set text(fill: rgb("#0070C1"))
  // @func: navy
  show regex("@[\w\d._]+"): set text(fill: navy)
  // dialect.operation: the dialect in blue, the operation in olive
  show regex("[\w\d_]+\.[\w\d_]+"): op => {
    let parts = op.text.split(".")
    text(fill: rgb("#0070C1"))[#parts.at(0)]
    text(fill: black)[.]
    text(fill: rgb("#999900"))[#parts.at(1)]
  }
  it
}

#set page(numbering: "1")

这是我论文的主体部分翻译为中文后的结果。所以，可能会比较正式一点，行文也没有那么自然。

= 背景知识
#include "chapters/preparation_zh.typ"

= 具体实现
#include "chapters/implementation_zh.typ"

= 评估 <eval>
#include "chapters/evaluation_zh.typ"

#bibliography("ref.bib")
