#import "@preview/cetz:0.4.2"
#import "utils.typ": *

#set math.mat(align: right)
#figure(caption: [Finding an integer basis of $upright("null")(A)$.])[
#cetz.canvas({
  import cetz.draw: *

  group({
    content((0, 0))[$
      underbrace(mat(
        2, 3, 4, 5;
        5, 6, 7, 8;
        8, 9, 1, 2
      ), A)
    $]
  })

  group({
    translate((3.75, 0))
    content((0, 0))[$
      underbrace(mat(
        2, 5, 8;
        3, 6, 9;
        4, 7, 1;
        5, 8, 2
      ), A^T)
    $]
  })

  group({
    translate((10, 0))
    content((0, 0))[$
      underbrace(mat(
        1, 1, 1;
        0, 3, 6;
        0, 0, 9;
        text(fill: #blue, 0), text(fill: #blue, 0), text(fill: #blue, 0)
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
      ), A^T)
    $]
  })

  group({
    translate((10, -4))
    content((0, 0))[$
      underbrace(mat(
        1, 0, 0, text(fill: #blue, 0);
        1, 3, 0, text(fill: #blue, 0);
        1, 6, 9, text(fill: #blue, 0)
      ), H^T) = 
      underbrace(mat(
        2, 3, 4, 5;
        5, 6, 7, 8;
        8, 9, 1, 2
      ), A)
      underbrace(mat(
        -1, 3, -1, text(fill: #blue, -1);
        -1, 2, 2, text(fill: #blue, 1);
        0, 0, -1, text(fill: #blue, 1);
        0, 0, 0, text(fill: #blue, -1)
      ), U^T)
    $]
  })

  group({
    translate((4, -3.75))
    content((0, 0))[$
      mat(-1; 1; 1; -1)
    $]
  })

  step((1.125, 0.25), (2.875, 0.25), black)[Transpose]
  step((4.625, 0.25), (6.375, 0.25), black)[Hermite]
  step((10, -1.45), (10, -2.75), black)[Transpose]
  step((6.15, -3.75), (4.65, -3.75), black)[Read off]
})
] <int-basis>
