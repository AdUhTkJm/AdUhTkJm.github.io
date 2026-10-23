#import "@preview/cetz:0.4.2"
#import "utils.typ": *

#let base = rgb("#AF00DB")
#let dim-1 = rgb("#007700")
#let dim-2 = rgb("#0000CC")

#show raw.where(lang: "mlir-offset-example"): it => {
  // #attr: orange
  show regex("#[\w\d._]+"): set text(fill: rgb("#A31515"))
  // !type: blue
  show regex("![\w\d._]+"): set text(fill: rgb("#0070C1"))
  // dialect.operation: 
  show regex("cir\.get_element"): op => {
    let parts = op.text.split(".")
    let dialect = parts.at(0)
    let operation = parts.at(1)
    
    text(fill: rgb("#0070C1"))[#dialect]
    text(fill: black)[.]
    text(fill: rgb("#999900"))[#operation]
  }

  show regex("(%69|%A)"): set text(fill: base)
  show regex("(%68|%j)"): set text(fill: dim-2)
  show regex("(%55|%53|%i)"): set text(fill: dim-1)
  it
}

#figure(caption: [Worked example of base and offset identification.])[
#cetz.canvas({
  import cetz.draw: *
  content((0, 0))[
    ```mlir-offset-example
    affine.for %i = #0 to #120 {
      %53 = cir.from_index %i
      %55 = cir.sub #119, %53
      affine.for %j = %67 to %11 {
        %68 = cir.from_index %j
        %69 = cir.get_element %A[%55]
        %70 = cir.get_element %69[%68]
      }
    }
    ```
  ]

  step((-5, -7/16), (-3, -7/16), base)[base: `%A`]
  step((5.5, -1), (3.5, -1), dim-2)[dim 2: $j$]
  step((3, 1.5), (3, -0.2), dim-1)[dim 1: $119 - i$]
})
] <offset-example>
