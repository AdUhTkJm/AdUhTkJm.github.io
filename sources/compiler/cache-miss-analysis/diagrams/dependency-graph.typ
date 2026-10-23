#import "@preview/cetz:0.4.2"
#import "@preview/fletcher:0.5.8": *
#import "utils.typ": *

#let blue(body) = {
  set text(fill: color.blue)
  body
}

#let green(body) = {
  set text(fill: color.green.darken(30%))
  body
}

#figure(caption: [Dependency graph.])[
#diagram(
  node((0, 0), blue[Count Compulsory Misses]),
  node((1, 0), blue[Reuse Distance]),
  node((2, 0), blue[Count Capacity Misses]),
  
  node((0, 1), green[Non-parametric Projection]),
  node((1, 1), green[Parametric Projection]),
  node((2, 1), green[Unimodular Decomposition]),

  node((0, 2), green[Find Particular Solution]),
  node((1, 2), green[Triangulation]),
  node((2, 2), green[Get Sample Point]),

  node((0, -1), blue[Dependency]),
  node((1, -1), green[Inclusion-Exclusion]),

  edge((0, -1), "->", (0, 0)),
  edge((0, 0), "->", (1, 0)),
  edge((1, 0), "->", (2, 0)),
  edge((0, 0), "<-", (0, 1)),
  edge((1, 1), "->", (2, 0)),
  edge((2, 1), "->", (2, 0)),
  edge((0, 2), "->", (0, 1)),
  edge((0, 2), "->", (1, 1)),
  edge((1, 2), "->", (2, 1)),
  edge((2, 2), "->", (2, 1)),
  edge((1, -1), "->", (0, 0)),
  edge((1, -1), "->", (2, 0)),
)
] <dependency-graph>
