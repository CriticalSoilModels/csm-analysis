// Status tags shared by the chapters of csm_analysis.typ.
// Generic tags (resolved, proposed, ...) come from template.typ.
#import "template.typ": status

#let open-tag = status("OPEN", orange)
#let debt     = status("TECH DEBT", luma(100))
#let deferred = status("DEFERRED", luma(100))
