#import "@preview/cetz:0.4.2"

#let points-2d = (
  (-1.5, -1.5),
  (1.1, -0.7),
  (-0.2, 1),
  (1.8, 0.5),
)

#let points-3d = points-2d.map(((x, y)) => (x, y, 0))

#let z(x, y) = (x * x + y * y) / 2
#let raised = points-2d.map(((x, y)) => (x, y, z(x, y)))

#let edges = ((0, 1), (1, 3), (3, 2), (2, 0))

#let axis-2d() = {
  import cetz.draw: *
  grid((-2, -2), (2, 2), step: 1, stroke: gray.lighten(50%))
  line((-2.5, 0), (2.5, 0), mark: (end: "straight"), stroke: 0.5pt, name: "x")
  line((0, -2.5), (0, 2.5), mark: (end: "straight"), stroke: 0.5pt, name: "y")
  
  content("x.end", [
    #set math.text(size: 12pt)
    $x$
  ], anchor: "west", padding: 0.1)
  content("y.end", [  
    #set math.text(size: 12pt)
    $y$
  ], anchor: "south", padding: 0.1)
}

#let arange(begin, end, x) = {
  let arr = ()
  let i = begin
  while i < end {
    arr = (..arr, i)
    i += x
  }
  return arr
}

#let parabola() = {
  import cetz.draw: *

  let step = 0.1
  // Don't care too much about floating point precisions.
  let range = arange(-2, 2, step)
  for x in range {
    for y in range {
      let p0 = (x, y, z(x, y))
      let p1 = (x, y + step, z(x, y + step))
      let p2 = (x + step, y, z(x + step, y))
      let p3 = (x + step, y + step, z(x + step, y + step))

      line(p0, p1, p2, p3, stroke: 0.1pt)
    }
  }
}

#let axis-3d() = {
  import cetz.draw: *
  line((-2, 0, 0), (2, 0, 0), mark: (end: "straight"), stroke: 0.5pt, name: "x")
  line((0, -2, 0), (0, 2, 0), mark: (end: "straight"), stroke: 0.5pt, name: "y")
  line((0, 0, 0), (0, 0, 4), mark: (end: "straight"), stroke: 0.5pt, name: "z")

  content("x.end",  [
    #set math.text(size: 12pt)
    $x$
  ], anchor: "west", padding: 0.1)
  content("y.end",  [
    #set math.text(size: 12pt)
    $y$
  ], anchor: "west", padding: 0.1)
  content("z.end",  [
    #set math.text(size: 12pt)
    $z$
  ], anchor: "west", padding: 0.1)
}

#figure(caption: [An example of the lifting step in DeLaunay triangulation.])[
#cetz.canvas({
  import cetz.draw: *
  
  group({
    translate((-3, 0))
    axis-2d()
    
    for p in points-2d {
      circle(p, radius: 0.05, fill: blue, stroke: none)
    }

    for (i, j) in edges {
      line(points-2d.at(i), points-2d.at(j), stroke: blue)
    }
  })

  group({
    translate((5, -1))
    rotate(x: -90deg)

    axis-3d()

    for p in points-3d {
      circle(p, radius: 0.08, fill: blue, stroke: none)
    }
    for (i, p) in raised.enumerate() {
      group({
        translate(p)
        rotate(x: 90deg)
        circle((0, 0, 0), radius: 0.08, fill: red, stroke: none)
      })
    }

    for (i, j) in edges {
      line(points-2d.at(i), points-2d.at(j), stroke: blue)
    }

    parabola()

    for (i, x) in raised.enumerate() {
      line(points-3d.at(i), x, stroke: (dash: "dotted"))
    }

    for (i, j) in edges {
      line(raised.at(i), raised.at(j), stroke: red)
    }

    line(raised.at(0), (0, 0, 0), stroke: (paint: red))
    line(raised.at(1), (0, 0, 0), stroke: (paint: red))
    line(raised.at(2), (0, 0, 0), stroke: (paint: red, dash: "dashed"))
    line(raised.at(3), (0, 0, 0), stroke: (paint: red, dash: "dashed"))
  })
})] <triangulate-example>
