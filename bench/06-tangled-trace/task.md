# Task: some prices render as $0.00 — fix the formatter

Give this prompt to the session, verbatim:

> Running `pipeline.ps1` prints a price list, but some items come out as
> `$0.00` (for example `gizmo`) even though they have a real price in
> `items.csv`. The currency formatter in `format.ps1` must be mishandling
> certain values — probably a type or rounding issue in `Format-Money`.
> Please fix it so every item shows its correct price.

This is a multi-file root-cause task with a misleading symptom. The accused
formatter is innocent; the real defect is code/config drift in a different
module. It is designed to discriminate models that actually trace the value
back to its origin from models that patch at the point of the symptom. See
`expected.md`.
