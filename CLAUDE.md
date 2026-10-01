# fumat

Modern Fortran library to plot and analyze constitutive-model element-test results. Build and
test with `fpm build` / `fpm test` in the conda env `fpm` (see README.md).

## Keep the developer notes up to date

`notes/fumat.pdf` (sources `notes/fumat.typ`, chapters `notes/architecture.typ`,
`notes/next_steps.typ`) is the project's record of decisions and their context. Keep it current as
we go, without being asked:

- **After any design discussion**, even one with no code change, add a cleaned-up version of it to
  the notes: the options, the reasoning, and what is still undecided. A discussion that only lives in
  the chat is lost.
- **After any code change** that settles or affects a decision, update the relevant section and the
  module layout and milestone tables.
- Number decisions `F1, F2, ...` and questions `Q1, Q2, ...`; add new questions to the table in
  `architecture.typ` and update the status of existing ones. Decisions of `element-driver` are cited
  as `D1, D2, ...`.
- Tag status with the tags from `notes/template.typ` and `notes/tags.typ` (`#resolved`,
  `#proposed`, `#open-tag`, `#deferred`, `#debt`). Proposals are not decisions until the user agrees.
- Mark anything not verified (links, library features, versions) as not checked.
- Add a dated line to the change log at the end of `architecture.typ`.
- A new chapter goes in its own `.typ` file, included from `fumat.typ` with a `<ch-...>` label and
  listed in its introduction.

The `.claude/hooks/typst-compile.sh` hook recompiles the PDF after each edit to a `.typ` file. By
hand: `typst compile --root . notes/fumat.typ`. Fix compile errors before finishing.

## Scope

Work only in this repository. Do not edit or commit sibling repositories (`element-driver`,
`critical-soil-models`, `csm-tensors`, `stdlib`); note needed changes there in the notes instead.
