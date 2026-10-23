#import "utils.typ": *

#figure(caption: [A 2-dimensional polyhedron and its halfspaces.])[
#scale(x: 85%, y: 85%, reflow: true)[
#cetz.canvas({
  import cetz.draw: *

  set-viewport((0, 0), (0.75, 0.75))

  let config = (
    ("line": (3, -1, 0), "color": green),
    ("line": (1, -4, 0), "color": red),
    ("line": (2, 3, -11), "color": blue),
  )

  group({
    translate((0, 0))
    axis-2d(4, 4)
    line((0, 0), (1, 3), (4, 1), (0, 0))
  })

  group({
    translate((12, 0))
    visualize-2d(config)
  })

  for i in range(3) {
    group({
      translate((i * 6, -7))
      visualize-2d((config.at(i), ))
      content((2, -1))[
        #fmt-line(config.at(i).line)
      ]
    })
  }

  step((6, 2), (10, 2), black)[Viewed as]
  step((14, -0.8), (14, -2.5), black)[Halfspaces]
})]
] <figure-halfspace>
