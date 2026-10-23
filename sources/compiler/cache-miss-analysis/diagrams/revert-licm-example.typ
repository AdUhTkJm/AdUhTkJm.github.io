#import "@preview/cetz:0.4.2"

#figure(caption: [IR before and after CSE.])[
#cetz.canvas({
  import cetz.draw: *

  content((-2.5, 0.5))[(a)]
  content((0, 0), anchor: "north")[
    ```mlir
    for i {
      %1 = cir.get_element
      for j { load %1 }
      load %1
    }
    ```
  ]

  content((3.5, 0.5))[(b)]
  content((6, 0), anchor: "north")[
    ```mlir
    for i {
      for j {
        %1 = cir.get_element
        load %1
      }
      %2 = cir.get_element
      load %2
    }
    ```
  ]
})
] <revert-licm-example>
