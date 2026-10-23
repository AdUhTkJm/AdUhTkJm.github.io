#import "@preview/cetz:0.4.2"

#figure(caption: [The model's predictions are highly approximate.])[
#cetz.canvas({
  import cetz.draw: *

  content((0, 0))[
    #std.scale(x: 50%, y: 50%, reflow: true)[
    #image("../images/relative-error-cdf.png")]
  ]
})
] <relerror-cdf>
