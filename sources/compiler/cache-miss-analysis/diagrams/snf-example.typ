#import "@preview/cetz:0.4.2"
#import "utils.typ": *

#set math.mat(align: right)

#figure(caption: [An example of Smith normal form.])[
#cetz.canvas({
  import cetz.draw: *

  content((0, 0))[
  $
    underbrace(mat(
      text(fill: #blue, 1), 0, 0;
      0, text(fill: #blue, 3), 0;
      0, 0, text(fill: #blue, 9);
      0, 0, 0
    ), D) =
    underbrace(mat(
      0, 0, 1, 0;
      0, 0, 2, -1;
      1, 0, 12, 10;
      -1, 1, 1, -1;
    ), U)
    underbrace(mat(
      2, 5, 8;
      3, 6, 9;
      4, 7, 1;
      5, 8, 2;
    ), A)
    underbrace(mat(
      0, 1, -2;
      0, 0, 1;
      1, -4, 1;
    ), V)
  $
  ]

  step((-6.5, 1), (-4.5, 1), blue)[Diagonal]
})
] <snf-example>
