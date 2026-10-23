#import "@preview/cetz:0.4.2"
#import "utils.typ": *

#figure(caption: [Workflow.])[
#cetz.canvas({
  import cetz.draw: *
  content((0, 0))[
    ```c for (i = 0; i < 800; i++)```
  ]
  content((0, -2))[
    ```mlir cir.for { check %i < 800 } { body } { increment %i }```
    #footnote[Abbreviated. See @ir-raising for full details.]
  ]
  content((0, -4))[
    ```mlir affine.for %i from 0 to 800```
  ]
  content((0, -8.5))[
    Misses: 159963
  ]

  group({
    translate((0, -6.5))
    scale(80%)
    let top = (0, 1, -0.2)
    let v0 = (1, 0, 0)
    let v1 = (calc.cos(120deg), 0, calc.sin(120deg))
    let v2 = (calc.cos(240deg), 0, calc.sin(240deg))

    line(top, v0)
    line(top, v1)
    line(top, v2, stroke: dashed)

    line(v0, v1)
    line(v0, v2, stroke: dashed)
    line(v1, v2, stroke: dashed)
  })

  step((0, -0.5), (0, -1.5), black)[`clang`]
  step((0, -2.5), (0, -3.5), black)[Raise]
  step((0, -4.5), (0, -5.5), black)[Model]
  step((0, -7), (0, -8), black)[Count]
})
] <workflow>
