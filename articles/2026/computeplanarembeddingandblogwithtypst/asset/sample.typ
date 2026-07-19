#import "@preview/cetz:0.5.0"
#set text(lang: "jp")
私は文章です。#footnote("我は脚注なり")

凄い数式:$f(x) = 1/x^2 sin (1/x)$

#figure(caption: "I am a table", table(
  columns: 2,
  table.header("桁", "数"),
  "1", "3",
  "2", "1",
  "3", "4",
))

#figure(caption: "吾輩は図である", html.frame(cetz.canvas({
  import cetz.draw: *
  catmull((-0.90, 1.65), (-1, 0), (1, 0), (0.90, 1.65), (0, 2), close: true, name: "i")
  for-each-anchor("i", name => {
    circle("i." + name, radius: .1, fill: blue)
  })
})))
