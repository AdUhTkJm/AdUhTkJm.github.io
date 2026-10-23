#import "@preview/cetz:0.4.2"

#figure(caption: [Majority of time is spent in Barvinok's algorithm.])[
#cetz.canvas({
  import cetz.draw: *

  content((0, 0))[
    #std.scale(x: 50%, y: 50%, reflow: true)[
    #image("../images/perf-percentage.png")]
  ]
})
] <time-breakdown>
