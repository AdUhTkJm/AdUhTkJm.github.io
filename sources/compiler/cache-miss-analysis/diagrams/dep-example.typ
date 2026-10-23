#import "@preview/cetz:0.4.2"

#figure(caption: [依赖关系的例子。])[
#cetz.canvas({
  import cetz.draw: *

  content((0, 0))[
    #show raw: it => {
      show regex("load"): set text(fill: blue)
      it
    }
    ```python
    for i in 0..7:
      load a[i] # T

    for i in 0..7:
      load b[i]

    for j in 6..2:
      load a[j] # S
    ```
  ]

  bezier((1, -1.5), (1, 1), (2, -0.25), mark: (end: "straight"), name: "depend")
  content("depend.mid")[
    #move(dx: 55pt)[Depend when $j = i$]
  ]
})] <dep-example>
