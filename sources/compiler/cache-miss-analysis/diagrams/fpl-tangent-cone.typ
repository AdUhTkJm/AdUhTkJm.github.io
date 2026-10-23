#import "@preview/cetz:0.4.2"
#import "utils.typ": *

#let v0 = (0, 0)
#let v1 = (1, 3)
#let v2 = (3, 2)
#let v3 = (2, 3)

#let lines = (
  line-between(v0, v1),
  line-between(v0, v2),
  line-between(v1, v3),
  line-between(v2, v3)
)

#let poly-2d() = {
  import cetz.draw: *

  fill(blue.lighten(60%).opacify(-50%))
  line(v0, v1, v3, v2, close: true, stroke: blue + 1.5pt)
}

#let draw-lines(i, j) = {
  import cetz.draw: *
  let l1 = lines.at(i)
  let l2 = lines.at(j)

  let (x, y) = intersect(l1, l2)

  let min = (-0.5, -0.5)
  let max = (4.5, 4.5)
  let (p0, p1) = clipping(min, max, l1)
  let (p2, p3) = clipping(min, max, l2)

  line(p0, p1, stroke: orange)
  line(p2, p3, stroke: orange)
  point((x, y))
}

#figure(caption: [Identification of tangent cones.])[
#cetz.canvas({
  import cetz.draw: *

  group({
    translate((7.5, 0))
    scale(0.5)

    axis-2d(4, 4, label-size: 9pt)
    poly-2d()
  })

  let pairs = ((0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3))
  for (k, (i, j)) in pairs.enumerate() {
    group({
      translate((k * 3, -4))
      scale(0.5)

      axis-2d(4, 4, label-size: 9pt)
      poly-2d()
      draw-lines(i, j)
    })
  }
  
  let pairs = ((0, 1), (0, 2), none, none, (1, 3), (2, 3))
  for (k, w) in pairs.enumerate() {
    group({
      if (w == none) {
        continue;
      }
      let (i, j) = w;
      translate((k * 3, -8))
      scale(0.5)

      axis-2d(4, 4, label-size: 9pt)
      poly-2d()
      draw-lines(i, j)
    })
  }

  step((8.5, -0.25), (8.5, -1.5), black)[Enumerate all inequality pairs]
  step((8.5, -4.25), (8.5, -5.75), black)[Filter: vertex inside polyhedron]
})
] <fpl-tangent-cone>
