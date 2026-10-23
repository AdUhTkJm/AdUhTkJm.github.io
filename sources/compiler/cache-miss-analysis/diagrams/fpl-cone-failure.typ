#import "@preview/cetz:0.4.2"
#import "utils.typ": *

#let axis(label-size: 12pt) = {
  import cetz.draw: *

  line((-2, 0, 0), (2, 0, 0), mark: (end: "straight"), stroke: 0.5pt, name: "x")
  line((0, -0.5, 0), (0, 2, 0), mark: (end: "straight"), stroke: 0.5pt, name: "y")
  line((0, 0, -2), (0, 0, 2), mark: (end: "straight"), stroke: 0.5pt, name: "z")

  content("x.end",  [
    #set math.text(size: label-size)
    $x$
  ], anchor: "west", padding: 0.1)
  content("y.end",  [
    #set math.text(size: label-size)
    $y$
  ], anchor: "west", padding: 0.1)
  content("z.end",  [
    #set math.text(size: label-size)
    $z$
  ], anchor: "west", padding: 0.1)
}

#let top = (0.3, 1, -0.3)
#let bottom = (
  (0, 0, 1),
  (0, 0, -1),
  (1, 0, 0),
  (-1, 0, 0)
)
#let (v0, v1, v2, v3) = bottom

#let poly() = {
  import cetz.draw: *

  line(top, v0)
  line(top, v2)
  line(top, v3)
  line(top, v1, stroke: dashed)

  for (i, j) in ((0, 2), (0, 3)) {
    line(bottom.at(i), bottom.at(j))
  }
  for (i, j) in ((1, 2), (1, 3)) {
    line(bottom.at(i), bottom.at(j), stroke: dashed)
  }
}

#let poly-1(colors) = {
  import cetz.draw: *

  let (a, b, c, d) = colors
  line(top, v0, v2, top, fill: a.transparentize(60%))
  line(top, v0, v3, top, fill: b.transparentize(60%))
  line(top, v1, v2, top, stroke: dashed, fill: c.transparentize(60%))
  line(top, v1, v3, top, stroke: dashed, fill: d.transparentize(60%))
}

#figure(caption: [A failure mode of tangent cone identification.])[
#cetz.canvas({
  import cetz.draw: *
  
  group({
    translate((-1.5, 0))
    poly()
  })

  let colors = (blue, green, red, gray)
  for (k, xs) in ((0, 1, 2, 3), (1, 2, 3, 0), (2, 3, 1, 0), (3, 1, 2, 0)).enumerate() {
    group({
      translate((3 * k - 6, -3))
      poly-1(range(4).map(x => colors.at(xs.at(x))))
    })
  }

  step((-1.5, -0.75), (-1.5, -1.75), black)[Enumerate inequality triples]
})
] <fpl-cone-failure>
