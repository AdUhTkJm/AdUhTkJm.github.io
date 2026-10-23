#import "@preview/cetz:0.4.2"
#import "utils.typ": *

#set math.mat(align: right)
#figure(caption: [An example of Hermite normal form.])[
#cetz.canvas({
  import cetz.draw: *

  content((0, 0))[
    $ 
      underbrace(mat(
        text(fill: #blue, 1), 1, 1;
        0, text(fill: #blue, 3), 6;
        0, 0, text(fill: #blue, 9);
        0, 0, 0
      ), H) =
      underbrace(mat(
        -1, -1, 0, 0;
        3, 2, 0, 0;
        -1, 2, -1, 0;
        -1, 1, 1, -1
      ), U)
      underbrace(mat(
        2, 5, 8;
        3, 6, 9;
        4, 7, 1;
        5, 8, 2
      ), A)
    $
  ]

  line((-3.5, 1.2), (-2, -0.7), stroke: (dash: "dashed", paint: red))

  step((-5, 0), (-3.6, 0), red)[upper]
  content((-4.4, -0.35))[#set text(fill: red.darken(20%)); triangular]

  step((-3.25, 2), (-3.25, 1.3), blue)[Pivot]
})
] <hnf-example>
