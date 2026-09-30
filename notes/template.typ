// Shared styling for the project's math/physics notes.
//
// Usage (path relative to the note):
//   #import "template.typ": *
//   #show: note.with(title: "...", subtitle: "...")
//
// Compile every note to a PDF next to its source:
//   typst compile --root . notes/<name>.typ

#let note(title: none, subtitle: none, body) = {
  set document(title: title)
  set page(margin: 2.2cm, numbering: "1")
  set text(size: 10.5pt)
  set heading(numbering: "1.1")
  set math.equation(numbering: "(1)")
  set table(stroke: 0.5pt + luma(180))
  show raw: set text(size: 9pt)

  align(center)[
    #text(size: 16pt, weight: "bold", title)
    #if subtitle != none [ #v(2pt) #subtitle ]
  ]
  body
}

// Inline code reference, e.g. #code("mcss_functions.f90:55")
#let code(path) = raw(path)

// Status tags
#let status(s, col) = box(
  fill: col.lighten(80%), inset: (x: 4pt, y: 2pt), radius: 2pt,
  text(fill: col.darken(30%), weight: "bold", s),
)
#let verified  = status("VERIFIED BY FD", green)
#let failing   = status("FAILS FD CHECK", red)
#let proposed  = status("PROPOSED", orange)
#let departure = status("DEPARTS FROM LEGACY", purple)
#let resolved  = status("RESOLVED", green)
#let superseded = status("SUPERSEDED", luma(100))

// Callout box for warnings / status updates
#let callout(title, col, body) = block(
  width: 100%, inset: 8pt, radius: 3pt,
  fill: col.lighten(90%), stroke: (left: 3pt + col),
  [*#title* \ #body],
)
