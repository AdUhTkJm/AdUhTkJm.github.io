#import "@preview/cetz:0.4.2"
#import "utils.typ"

#figure(caption: [An example of a 3-dimensional cone (black part).])[
#cetz.canvas({
  import cetz.draw: *

  // set-viewport((0, 0, 0), (3, 3, 3))
  
  let top = (0, 2, 0)
  let vertices = (
    (0, 0, 1),
    (0, 0, -1),
    (2, 0, 0),
    (-2, 0, 0)
  )
  
  for x in vertices {
    let (a, b, c) = x
    let (d, e, f) = top
    let (dx, dy, dz) = (a - d, e - b, f - c).map(w => w * 1.3)
    line(top, (d - dx, e - dy, f - dz))
  }
  for (start, end) in ((0, 2), (1, 3), (0, 3), (1, 2)) {
    line(vertices.at(start), vertices.at(end), stroke: gray.lighten(30%))
  }
})
] <cone-example>
