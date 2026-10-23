#import "@preview/cetz:0.4.2"
#import "../build/repo.typ" as repo


#let omit-threshold = 10
#let data = repo.repo.filter(((del, add, path)) =>
  not (path.ends-with(".txt") or path.ends-with(".sh"))
  and add >= omit-threshold
)

#let grouped = (:)
#let not-newly-introduced = (
  "PWMAFunction.cpp",
  "IntegerRelationTest.cpp"
)

#for item in data {
  let (del, add, path) = item
  let parts = path.split("/")
  
  // The filename is the last part; the prefix is everything before it
  let filename = parts.pop()
  let prefix = parts.join("/")
  
  // Initialize the array for this prefix if it doesn't exist
  if prefix not in grouped {
    grouped.insert(prefix, ())
  }
  
  // Add the processed tuple to the dictionary
  grouped.at(prefix).push((del, add, filename))
}

#let i = 0
#figure(caption: [Repository overview.])[
#set text(font: "Consolas", size: 10pt)
#cetz.canvas({
  import cetz.draw: *

  for (k, v) in grouped {
    i += 1
    content((-2, -i / 2), anchor: "west")[
      #set text(fill: gray.darken(30%))
      #k
    ]

    for (del, add, name) in v {
      i += 1
      content((-1.25, -i / 2), anchor: "west")[
        #if (del == 0 and name not in not-newly-introduced) {
          set text(fill: blue)
          name
        } else {
          name
        }
      ]
      content((8, -i / 2), anchor: "west")[
        #set text(fill: green.darken(20%))
        +#add
      ]
      content((9.2, -i / 2), anchor: "west")[
        #set text(fill: red.darken(20%))
        -#del
      ]
    }
  }
})
] <repo-overview>