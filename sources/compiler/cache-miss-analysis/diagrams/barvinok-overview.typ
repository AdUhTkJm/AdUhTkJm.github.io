#import "@preview/cetz:0.4.2"
#import "utils.typ": *

#let poly-3d() = {
  import cetz.draw: *
  set-viewport((0, 0, 0), (3, 3, 3), bounds: (1, 1, 1))
  
  line((0, 0, 0), (1, 0, 0), mark: (end: "straight"), name: "x-axis")
  line((0, 0, 0), (0, 1, 0), mark: (end: "straight"), name: "y-axis")
  line((0, 0, 0), (0, 0, 1), mark: (end: "straight"), name: "z-axis")
  
  // Add axis labels.
  content("x-axis.end", pad([$x$], 2pt), anchor: "west")
  content("y-axis.end", pad([$y$], 2pt), anchor: "south")
  content("z-axis.end", pad([$z$], 2pt), anchor: "east")

  // Draw the polygon on the x-z plane.
  let polygon = (
    (0, 0, 0),
    (3, 0, 1),
    (3, 0, 3),
    (1, 0, 3)
  ).map(x => x.map(y => y * 0.35))

  fill(blue.lighten(60%))
  line(
    ..polygon,
    close: true,
    stroke: blue
  )
}

#let axis() = {
  import cetz.draw: *;
  // Draw a coordinate grid.
  grid((0,0), (4,4), step: 1, stroke: gray.lighten(50%))
  
  // Draw the axes.
  line((-0.5, 0), (4.5, 0), mark: (end: "straight"), stroke: 0.5pt, name: "x1")
  line((0, -0.5), (0, 4.5), mark: (end: "straight"), stroke: 0.5pt, name: "x2")
  
  content("x1.end", [$x_1$], anchor: "west", padding: 0.1)
  content("x2.end", [$x_2$], anchor: "south", padding: 0.1)
}

#let v0 = (0, 0)
#let v1 = (1, 3)
#let v2 = (3, 1)
#let v3 = (3, 3)

#let poly-2d() = {
  import cetz.draw: *;
  axis();

  fill(blue.lighten(60%).opacify(-50%))
  line(v0, v1, v3, v2, close: true, stroke: blue + 1.5pt)
}

#let stretch = 1.6

#let poly-2d-cone(top, v1, v2) = {
  import cetz.draw: *;
  poly-2d()

  // Highlight the Generator Vectors.
  line(top, v1, stroke: blue + 2pt, mark: (end: "stealth"))
  line(top, v2, stroke: blue + 2pt, mark: (end: "stealth"))

  // Highlight the cone.
  let (xt, yt) = top

  let stretched(v) = {
    let (x, y) = v
    (x - (xt - x) * (stretch - 1),
     y - (yt - y) * (stretch - 1))
  }

  line(top, stretched(v1), stretched(v2), stroke: none)
}

#let cones = (
  (coords: ((0,0), (1,3), (1,2)), color: red,   res: "173/1440"),
  (coords: ((0,0), (1,2), (1,1)), color: gray,  res: "95/1440"),
  (coords: ((0,0), (1,1), (2,1)), color: purple,res: "..."),
  (coords: ((0,0), (2,1), (3,1)), color: green, res: "..."),
)

// We're computing the result of generating function with a cone pointed at `top`, and other two points `v1` and `v2`.
// We find a vector v = (1, 1) that isn't orthogonal to any of the vectors (otherwise it will panic).
#let barvinok-constant(top, v1, v2) = {
  let (xs, ys) = top
  let (xv, yv) = (1, 1)
  let sp = xs * xv + ys * yv

  // The generators are actually v1 - top and v2 - top.
  let (x1, y1) = (v1.at(0) - xs, v1.at(1) - ys)
  let (x2, y2) = (v2.at(0) - xs, v2.at(1) - ys)
  assert(calc.gcd(x1, y1) == 1)
  assert(calc.gcd(x2, y2) == 1)

  let s1 = x1 * xv + y1 * yv
  let s2 = x2 * xv + y2 * yv
  assert(s1 != 0 and s2 != 0)
  
  let num = 6 * sp * sp - 6 * sp * (s1 + s2) + s1 * s1 + s2 * s2 + 3 * s1 * s2
  let den = 12 * s1 * s2
  
  let gcd = calc.gcd(int(num), int(den))
  (int(num / gcd), int(den / gcd))
}

#let monomial(v) = {
  let (x, y) = v
  let num = if x == 0 and y == 0 {
    $1$
  } else {
    let tx = if x == 0 {
      ""
    } else if x == 1 {
      $x_1$
    } else {
      $x_1^#x$
    }
    let ty = if y == 0 {
      ""
    } else if y == 1 {
      $x_2$
    } else {
      $x_2^#y$
    }
    $#tx #ty$
  }
  return num
}

// We display the formula.
#let generating-function(top, v1, v2) = {
  let num = if top.at(0) == 0 and top.at(1) == 0 {
    $1$
  } else {
    let tx = if top.at(0) != 0 { $x_1^{#(top.at(0))}$ } else { "" }
    let tz = if top.at(1) != 0 { $x_2^{#(top.at(1))}$ } else { "" }
    $#tx #tz$
  }

  let term1 = $(1 - x_1^#(v1.at(0)) x_2^#(v1.at(1)))$
  let term2 = $(1 - x_1^#(v2.at(0)) x_2^#(v2.at(1)))$
  
  $ #num / ((1 - #monomial(v1)) (1 - #monomial(v2))) $
}

#let poly-2d-unimod() = {
  import cetz.draw: *;
  poly-2d()

  let dot(pos) = {
    circle(pos, radius: 0.08, fill: red, stroke: none)
  }

  dot((1, 2))
  dot((2, 1))
  dot((1, 1))

  // The line is actually determined by these two points.
  let (x0, y0) = (3, 1).map(x => x * stretch)
  let (x1, y1) = (1, 3).map(x => x * stretch)

  // So when we represent it as kx + b, we get
  let k = (y1 - y0) / (x1 - x0)
  let b = y0 - k * x0

  // For cones, its generators' ending point must reside on the given line.
  let cone(v2, v3, color) = {
    let (x2, y2) = v2
    let (x3, y3) = v3

    let k2 = y2 / x2
    let k3 = y3 / x3

    // The intersection between y = kx + b and y = k2x is
    // x = b / (k2 - k).
    let p2 = b / (k2 - k)
    let p3 = b / (k3 - k)

    line((0, 0), (p2, k2 * p2), (p3, k3 * p3), fill: color.opacify(-50%), stroke: none)

    // Also draw the generators.
    line((0, 0), v2, v3, fill: color.opacify(-30%))
  }

  for x in cones {
    cone(..x.coords.slice(1), x.color)
  }
}

#let poly-iterate(cone) = {
  import cetz.draw: *;
  axis();

  line(..cone.coords, close: true, fill: cone.color.opacify(-50%))
}

#let legend() = {
  import cetz.draw: *
  
  let item(y, color, label) = {
    line((0, y), (0.8, y), stroke: color, mark: (end: "straight"))
    content((1, y), text(size: 9pt, label), anchor: "west")
  }

  item(0.8, green, [Implemented])
  item(0.4, red,   [Bug fixes])
  item(0,   black, [Untouched])
  
  // Optional: Draw a subtle border around the legend
  rect((-0.2, -0.3), (4.5, 1.1), stroke: gray.lighten(50%), fill: gray.opacify(-80%))
}

// When drawing the next few slides, our slide counter will be frozen, and won't add 1.
// So we increase it here.
#let sum = (0, 1)
#let frac-add((x1, y1), (x2, y2)) = {
  let num = x1 * y2 + x2 * y1
  let den = y1 * y2
  let gcd = calc.gcd(num, den)
  return (int(num / gcd), int(den / gcd))
}

#figure(caption: [An overview of Barvinok's algorithm.])[
#scale(x: 50%, y: 50%, reflow: true)[
#cetz.canvas({
  import cetz.draw: *

  group({ poly-3d() })

  group({
    translate((-2, -23))
    scale(x: 150%, y: 150%)
    legend()
  })

  step((3, 1), (5, 1), green)[Project]
  group({
    translate((5.5, -1.5))
    poly-2d()
  })

  step((10, 1), (12, 1), red)[Tangent Cone]
  group({
    translate((12.5, -1.5))
    poly-2d-cone(v0, v1, v2)
  })

  if false {
    step((10, 1), (12, 1), red)[Tangent Cone]
    group({
      translate((12.5, -1.5))
      poly-2d-cone(v2, v3, v0)
    })
    content((21, 0.5))[
      #set text(size: 20pt)
      $ -129 / 16 $
      (Symmetric on other side)
    ]

    step((10, -6), (12, -6), red)[Tangent Cone]
    group({
      translate((12.5, -8.5))
      poly-2d-cone(v3, v1, v2)
    })
    content((21, -6.5))[
      #set text(size: 20pt)
      #let (n, d) = barvinok-constant(v3, (3, 2), (2, 3))
      $ #n / #d $
    ]

    group({
      translate((2, -5))
      content((0, 0))[
        #set text(size: 20pt, fill: blue)
        Total: $10$
      ]
    })
  }

  step((17, 1), (19, 1), green)[Unimod. Decomp.]
  group({
    translate((19.5, -1.5))
    poly-2d-unimod()
  })
  
  step((21, -2), (21, -4), black)[Iterate]

  for s in range(4) {
    let cone = cones.at(s)
    
    group({
      translate((0, -s * 5))
      group({
        translate((19.5, -8.5))
        poly-iterate(cone)
      })

      step((19, -6), (16, -6), black)[Generating Function]
      group({
        translate((12.5, -6))
        content((0, 0))[
          #set text(20pt)
          #generating-function(..cone.coords)
        ]
      })

      step((9, -6), (7, -6), black)[Evaluate]
      group({
        translate((6, -6))
        content((0, 0))[
          #set text(20pt)
          #let (n, d) = barvinok-constant(..cone.coords)
          $ #n/#d $

          #(sum = frac-add(sum, (n, d)))
        ]
      })
    })
  }
})
]] <barvinok-overview>
