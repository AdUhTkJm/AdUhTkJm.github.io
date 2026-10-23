#import "@preview/cetz:0.4.2"

#figure(caption: [Our analysis is efficient enough but yet has large room for optimisation.])[
#cetz.canvas({
  import cetz.draw: *

  content((0, 0))[
    #std.scale(x: 50%, y: 50%, reflow: true)[
    #image("../images/time-mine-to-falcon.png")]
  ]

  content((9, 0))[
    #std.scale(x: 50%, y: 50%, reflow: true)[
    #image("../images/time-mine-to-perf.png")]
  ]
})
] <time-cmp>
