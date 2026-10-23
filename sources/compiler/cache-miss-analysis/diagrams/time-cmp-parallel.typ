#import "@preview/cetz:0.4.2"

#figure(caption: [Speedup from parallelisation.])[
#cetz.canvas({
  import cetz.draw: *

  content((0, 0))[
    #std.scale(x: 50%, y: 50%, reflow: true)[
    #image("../images/time-mine-to-non-par.png")]
  ]
})
] <time-cmp-parallel>
