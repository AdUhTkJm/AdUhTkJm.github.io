#import "@preview/cetz:0.4.2"

#figure(caption: [The model predicts the scaling trend of cache misses, but fails to predict the absolute miss counts.])[
#cetz.canvas({
  import cetz.draw: *

  content((0, 0))[
    #std.scale(x: 50%, y: 50%, reflow: true)[
    #image("../images/miss-mine-to-perf-log.png")]
  ]

  content((1, -1.5))[$R^2 = 0.83$]

  content((9, 0))[
    #std.scale(x: 50%, y: 50%, reflow: true)[
    #image("../images/miss-mine-to-perf-linear.png")]
  ]
  content((10, -1.5))[$R^2 = 0.18$]
})
] <miss-cmp>
