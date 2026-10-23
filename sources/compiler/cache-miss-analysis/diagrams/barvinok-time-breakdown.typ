#import "@preview/cetz:0.4.2"

#figure(caption: [Most time is spent in inclusion-exclusion regardless of disjunct count.])[
#cetz.canvas({
  import cetz.draw: *

  // content((0, 0))[
  //   #std.scale(x: 50%, y: 50%, reflow: true)[
  //   #image("../images/barvinok-breakdown.png")]
  // ]

  content((0, 0))[
    #std.scale(x: 50%, y: 50%, reflow: true)[
    #image("../images/barvinok-breakdown-percent.png")]
  ]
})
] <barvinok-time-breakdown>
