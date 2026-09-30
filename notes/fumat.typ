#import "template.typ": *
#import "tags.typ": *
#show: note.with(
  title: "fumat",
  subtitle: [Architecture, decisions, and change log · started 2026-09-30],
)

This is the single developer document for `fumat`. Compile it from the repository root with
`typst compile --root . notes/fumat.typ`; the chapters live in `notes/architecture.typ` and are not
compiled on their own. The layout follows `element-driver/notes`, and `template.typ` is a copy of
the one there.

- @ch-arch covers where `fumat` sits among the CriticalSoilModels repositories, its decisions (F1,
  F2, ...), the proposed module layout, the open questions, and the milestones.

Decisions of `element-driver` are cited as D1, D2, ... (see `element-driver/notes/design.typ`).

*Tags.*
#resolved decided;
#proposed designed but not in code, awaiting agreement;
#open-tag not yet decided;
#deferred agreed to leave for later;
#debt style or structure, not correctness.

#outline(depth: 2, indent: auto)

#pagebreak()
= Architecture of `fumat` <ch-arch>
#[
  #set heading(offset: 1)
  #include "architecture.typ"
]
