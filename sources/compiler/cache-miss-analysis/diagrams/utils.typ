#import "@preview/cetz:0.4.2"

#let step(from, to, color, body) = {
  import cetz.draw: *
  let name = "step"
  // This group is to create a scope.
  group({
    line(from, to, 
      mark: (end: "straight"),
      name: name,
      stroke: color.lighten(-20%)
    )
    content(name + ".mid", [
      #set text(fill: color.lighten(-20%))
      #body
    ], anchor: if (to.at(0) == from.at(0)) {
      "west"
    } else {
      "south"
    }, padding: 0.2)
  })
}

#let axis-2d(x, y, label-size: 12pt) = {
  import cetz.draw: *;
  // Draw a coordinate grid.
  grid((0, 0), (x, y), step: 1, stroke: gray.lighten(50%))
  
  // Draw the axes.
  line((-0.5, 0), (x + 0.5, 0), mark: (end: "straight"), stroke: 0.5pt, name: "x")
  line((0, -0.5), (0, y + 0.5), mark: (end: "straight"), stroke: 0.5pt, name: "y")
  
  content("x.end", [
    #set math.text(size: label-size)
    $x$
  ], anchor: "west", padding: 0.1)
  content("y.end", [  
    #set math.text(size: label-size)
    $y$
  ], anchor: "south", padding: 0.1)
}

#let axis-3d(x: 1, y: 1, z: 1, label-size: 12pt) = {
  import cetz.draw: *

  line((0, 0, 0), (x, 0, 0), mark: (end: "straight"), stroke: 0.5pt, name: "x")
  line((0, 0, 0), (0, y, 0), mark: (end: "straight"), stroke: 0.5pt, name: "y")
  line((0, 0, 0), (0, 0, z), mark: (end: "straight"), stroke: 0.5pt, name: "z")

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

#let intersect(l1, l2) = {
  let (a1, b1, c1) = l1
  let (a2, b2, c2) = l2

  if a1 * b2 == a2 * b1 {
    panic("parallel lines: " + repr(l1) + ", " + repr(l2))
  }
  
  return (
    (c2 * b1 - c1 * b2) / (a1 * b2 - a2 * b1),
    (c2 * a1 - c1 * a2) / (b1 * a2 - b2 * a1)
  )
}

#let line-between((x1, y1), (x2, y2)) = {
  let a = y2 - y1
  let b = x1 - x2
  let c = x2 * y1 - x1 * y2
  let gcd = calc.gcd(c, calc.gcd(a, b))
  return (a, b, c).map(x => int(x / gcd))
}

#let point((x, y), color: red) = {
  import cetz.draw: *

  circle((x, y), fill: color, radius: 0.12, stroke: none)
}

#let clipping((minw, minh), (maxw, maxh), l) = {
  import cetz.draw: *

  let (a, b, c) = l
  if (b == 0) {
    return ((-c / a, minh), (-c / a, maxh))
  }
  if (a == 0) {
    return ((minw, -c / b), (maxw, -c / b))
  }

  let lines = (
    (1, 0, -minh),
    (1, 0, -maxh),
    (0, 1, -minw),
    (0, 1, -maxw),
  )
  let clipping = lines.map(x => intersect(x, l))
  // Choose the middle two.
  let (p0, p1) = clipping.sorted(key: it => it.at(1)).slice(1, 3)
  return (p0, p1)
}

#let halfspace(size, l, color) = {
  import cetz.draw: *
  let (w, h) = size
  let margin = 0.5

  // We want to clip on x = -0.5, x = 4.5, y = -0.5 and y = 4.5.
  let (p0, p1) = clipping(
    (-margin, -margin),
    (w + margin, h + margin),
    l
  )
  line(p0, p1, stroke: color)

  // The rest of the halfspace should be colored.
  if (p0.at(0) > p1.at(0)) {
    (p0, p1) = (p1, p0)
  }

  let (a, b, c) = l
  w += margin; h += margin
  if (a * margin + b * margin - c >= 0) {
    // Now (-0.5, -0.5) is on the correct side.
    line(p0,
      (calc.max(p0.at(0), -margin), -margin),
      (w, -margin),
      (w, calc.min(h, p1.at(1))),
      p1,
      fill: color.opacify(-80%), stroke: none
    )
  } else {
    // It's the other way around.
    line(p0,
      (-margin, h),
      (w, h),
      p1, fill: color.opacify(-80%), stroke: none)
  }
}

#let visualize-2d(config) = {
  import cetz.draw: *;

  let (w, h) = (4, 4)
  axis-2d(w, h)
  for (line, color) in config {
    halfspace((w, h), line, color)
  }
}

#let fmt-line(line) = {
  let (a, b, c) = line
  let fmt(w, letter, plus: true) = {
    if (w == 1) {
      return if (plus) { $+ #letter$ } else { $#letter$ } 
    }
    if (w == -1) {
      return $- #letter$
    }
    if (w > 0) {
      if (plus) { $+ #w #letter$ } else { $#w #letter$ }
    } else if (w < 0) {
      $- #(-w) #letter$
    } else { $$ }
  }
  let na = fmt(a, $x$, plus: false)
  let nb = fmt(b, $y$)
  let nc = fmt(c, $$)
  $#na #nb #nc >= 0$
}

#let dashed = (dash: (4pt, 2pt))
