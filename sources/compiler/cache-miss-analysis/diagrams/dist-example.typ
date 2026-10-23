#import "@preview/cetz:0.4.2"

#let cache-map() = {
  import cetz.draw: *
  grid((0, 0), (8, -3), name: "grid")
  content((-0.5, -0.5))[`a`]
  content((-0.5, -1.5))[`b`]
  content((-0.5, -2.5))[`a`]
}

#let fill-grid((x, y), color: blue) = {
  import cetz.draw: *
  y -= 1
  rect((x, y), (x + 1, y + 1), fill: color.opacify(-50%), stroke: none)
}

#figure(caption: [@dep-example 中，不同的 $j$ 访问缓存行的数目.])[
#scale(x: 75%, y: 75%, reflow: true)[
#cetz.canvas({
  import cetz.draw: *
  group({
    translate((0, 1))
    cache-map()
    content((4, 0.5))[$j = 6$:]
    for i in range(8) {
      fill-grid((i, -1))
    }
    fill-grid((6, -2), color: orange)
    fill-grid((6, 0), color: orange)
    fill-grid((7, 0))
  })

  group({
    translate((0, -3))
    cache-map()
    content((4, 0.5))[$j = 5$:]
    for i in range(8) {
      fill-grid((i, -1))
    }
    fill-grid((5, -2), color: orange)
    fill-grid((6, -2))
    fill-grid((5, 0), color: orange)
    fill-grid((6, 0)); fill-grid((7, 0))
  })
})]
] <dist-example>
