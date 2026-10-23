#import "@preview/cetz:0.4.2"

// Numpy polyfit:
//   0.26081116464185666 * x^1.9449604217194205
#figure(caption: [Speedup brought by caching chamber ownership.])[
#cetz.canvas({
  import cetz.draw: *

  content((0, 0))[
    #std.scale(x: 50%, y: 50%, reflow: true)[
    #image("../images/barvinok-summation-speedup.png")]
  ]
})
] <barvinok-cache-opt>
