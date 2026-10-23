#import "@preview/wordometer:0.1.5": word-count, total-words
#import "@preview/cetz:0.4.2"
#import "build/repo.typ"

#let font-size = 12pt;
#set text(size: font-size)
#let title = "Cache Miss Analysis with Polyhedral Model"
#let author = "Yue Huang"
#let bgn = "7417J"
#let supervisor = "Dr Tobias Grosser"
#{
  h(1fr)
  [BGN: #bgn]
  v(-0.5em)
  set align(center + horizon)
  std.title()[#title]
  [
    #set text(size: 16pt)
    *Exam*: Computer Science Tripos, Part II - 2026
  ]
}

#let chapter(id, title) = {
  set align(right);
  // Compensate for the inner -48pt, so the next paragraph starts at the correct place.
  stack(dir: ttb, spacing: 32pt, 
    stack(dir: ttb, spacing: -48pt, [
      #set text(120pt, fill: color.gray, weight: "regular");
      #id
    ], [
      #set text(32pt, weight: "bold"); #title
    ]),
  [])
}

#let repo-filtered = repo.repo.filter(((del, add, x)) => not x.ends-with(".txt"))
#let lines-added = repo-filtered.map(((del, add, x)) => add).sum()
#let lines-deleted = repo-filtered.map(((del, add, x)) => del).sum()

#show heading: it => {
  if (it.depth == 1) {
    pagebreak();
    // This is a string like "1."
    if (it.numbering != none) {
      let number = counter(heading).display(it.numbering);
      chapter(number.slice(0, -1), it.body)
    } else {
      set text(22pt)
      it.body
      v(5pt)
    }
  } else if (it.depth == 2) {
    set text(18pt)
    it
  } else if (it.depth == 3) {
    set text(13pt)
    it
    // Remove numbering.
  } else {
    panic("heading: unknown depth")
  }
}

#show link: it => {
  set text(fill: blue)
  it
}

#show raw.where(lang: "mlir"): it => {
  // %name: purple
  show regex("%[\w\d._]+"): set text(fill: rgb("#AF00DB"))
  // #attr: orange
  show regex("#[\w\d._]+"): set text(fill: orange)
  // !type: blue
  show regex("![\w\d._]+"): set text(fill: rgb("#0070C1"))
  // @func: navy
  show regex("@[\w\d._]+"): set text(fill: navy)
  // dialect.operation: 
  show regex("\d+"): set text(fill: rgb("#A31515"))
  show regex("[\w\d_]+\.[\w\d_]+"): op => {
    let parts = op.text.split(".")
    let dialect = parts.at(0)
    let operation = parts.at(1)
    
    text(fill: rgb("#0070C1"))[#dialect]
    text(fill: black)[.]
    text(fill: rgb("#999900"))[#operation]
  }
  it
}

#show par: it => {
  it
  v(-0.5em)
}

= Declaration of Originality

I, the candidate for Part II of the Computer Science Tripos with Blind Grading Number 7417J, hereby declare that this report and the work described in it are my own work, unaided except as may be specified below, and that the report does not contain material that has already been used to any substantial extent for a comparable purpose. In preparation of this report, I adhered to the Department of Computer Science and Technology AI Policy. I am content for my report to be made available to the students and staff of the University.

*Date:* #datetime.today().display("[day] [month repr:short], [year]")

= Proforma

#v(-1em)
#table(columns: 2, stroke: none,
[Candidate Number], [#bgn],
[Title], [#title],
[Examination], [Computer Science Tripos, Part II - 2026],
[Word Count], [#strong(total-words) #footnote()[Computed with Typst package `wordometer`: #link("https://typst.app/universe/package/wordometer")]],
[Code Line Count], [#[#show text: strong; #lines-added;] #footnote()[Computed with `git diff --numstat` from Clang IR repository, commit `e4003cd3a`. This is the number of lines added; #lines-deleted lines have been deleted.]],
[Project Originator], [The Candidate],
[Day-to-Day Supervisor], [#supervisor, Mr Arjun Pitchanathan],
[Marking Supervisor], [#supervisor],
[Ethics Approval], [Not Requested])

== Original Aims of the Project

This project aims to explore both the mathematics involved in polyhedral analysis, and the application of it on cache modelling. It involves testing and finishing a half-complete library in MLIR, and using the library to perform a static analysis that estimates the number of cache misses in an affine program.

== Work Completed

We completed the static analysis pass and enhanced the library, satisfying the success criteria according to the proposal. We also implemented several extensions, including optimisation of both the pass and the library.

== Special Difficulties

None.

#set heading(numbering: "1.")
#show outline.entry: it => {
  // Ignore previous sections that lack a prefix.
  if (it.prefix() == none and not repr(it.element.body).starts-with("[Appendix")) {
    return;
  }
  it
}
#outline(title: [Contents #v(0.5em)])
#outline(title: [List of Figures #v(0.5em)], target: figure)
#counter(page).update(0)
#set page(numbering: "1")

#word-count[
= Introduction

#include "chapters/introduction.typ"

= Preparation

#include "chapters/preparation.typ"

= Implementation

#include "chapters/implementation.typ"

= Evaluation <eval>

#include "chapters/evaluation.typ"

= Conclusions

#include "chapters/conclusion.typ"
]

#counter(heading).update(0)
#set heading(numbering: "A.1")
#set page(numbering: none)

#bibliography("ref.bib")

#pagebreak()

#place(
  top + right,
  [#set text(32pt); *Project Proposal*]
)

#for i in range(1, 7) {
  move(
    [#image("raw-data/proposal.pdf", page: i, width: 150%)],
    dx: -10em, dy: 0em
  )
}
