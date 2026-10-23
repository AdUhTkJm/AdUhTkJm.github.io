#import "@preview/cetz:0.4.2"
#import "utils.typ": *

#show raw.where(lang: "mlir-temp"): it => {
  // %name: purple
  show regex("%a\b"): set text(fill: rgb("#AF00DB"))
  show regex("%n\b"): set text(fill: rgb("#AF00DB"))
  // #attr: orange
  show regex("#[\w\d._]+"): set text(fill: orange)
  // !type: blue
  show regex("![\w\d._]+"): set text(fill: rgb("#0070C1"))
  // @func: navy
  show regex("@[\w\d._]+"): set text(fill: navy)
  // dialect.operation: 
  show regex("\d+"): set text(fill: rgb("#A31515"))
  show regex("cir\.(store|unary|cmp)"): op => {
    let parts = op.text.split(".")
    let dialect = parts.at(0)
    let operation = parts.at(1)
    
    text(fill: rgb("#0070C1"))[#dialect]
    text(fill: black)[.]
    text(fill: rgb("#999900"))[#operation]
  }
  it
}

#figure(caption: [Clang IR and `affine` dialect for a ```c for```-loop in C.])[
#cetz.canvas({
  import cetz.draw: *
  content((0, 0), anchor: "north-west")[
    ```mlir-temp
    cir.store %a, %i_addr
    cir.for : cond {
      %i    = cir.load %i_addr
      %cond = cir.cmp(lt, %i, %n)
      cir.condition(%cond)
    } body { ... } step {
      %i    = cir.load %i_addr
      %next = cir.unary(inc, %i)
      cir.store %next, %i_addr
    }
    ```
  ]

  content((-3, 0), anchor: "north-west")[`i = a`]
  content((-3, -3/2), anchor: "north-west")[`i < n`]
  content((-21/8, -27/8), anchor: "north-west")[`i++`]

  content((0, -6), anchor: "north-west")[
    ```mlir-temp
    affine.for %arg = %a to %n
    ```
  ]


  step((-15/8, -1/8), (-1/8, -1/8), black)[]
  step((-15/8, -13/8), (-1/8, -13/8), black)[]
  step((-15/8, -7/2), (-1/8, -7/2), black)[]

  step((2, -35/8), (2, -47/8), black)[Raise]
})] <cir-for-op>
