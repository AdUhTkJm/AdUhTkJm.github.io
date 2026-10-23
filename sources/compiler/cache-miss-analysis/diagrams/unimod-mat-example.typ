#import "@preview/cetz:0.4.2"

#set math.mat(align: right)
#figure(caption: [A unimodular matrix and its inverse.])[
#cetz.canvas({
  import cetz.draw: *

  content((0, 0))[
    $ M = mat(-2, 1; 5, -2) $  
  ]

  content((5, 0))[
    $ M^(-1) = mat(-2, -1; -5, -2) $
  ]
})
] <unimod-mat-example>
