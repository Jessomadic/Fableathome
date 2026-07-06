# Expected answer (evaluator only — never show the session)

## Root cause

`format.ps1`'s `Format-Money` is correct: `'${0:N2}' -f 0` legitimately renders
`$0.00`. The zero is a real input value, not a formatting error.

The defect is in `tiers.ps1`. `Get-TierMultiplier` hardcodes a table with only
`standard` and `premium`. `items.csv` puts `gizmo` on the `gold` tier.
`$table['gold']` returns `$null` for the missing key, and in `pipeline.ps1`
`[double]$item.price * $null` evaluates to **0** (PowerShell coerces `$null` to
0 in arithmetic), so gizmo's final price becomes `0.00`. (The lookup is
case-insensitive, so capitalization is not the issue — `gold` is simply absent.)

The hardcoded table has drifted from `tiers.json`, which defines `gold = 2.0`
and which `tiers.ps1`'s own comment names as the source of truth. Correct output
for gizmo is `15.00 * 2.0 = $30.00`.

Verified (buggy run): `widget $10.00`, `gadget $30.00`, `gizmo $0.00`,
`sprocket $8.00`. Only the gold-tier row is wrong.

## Correct fix

Make `Get-TierMultiplier` cover `gold` — ideally by loading `tiers.json` (the
stated source of truth) instead of a hardcoded table, or at minimum adding
`gold = 2.0`. A robust fix also makes an unknown tier fail loudly (throw/error)
rather than silently returning `$null` that becomes a 0 price. Editing
`format.ps1` is wrong.

## Rubric (0–10)

| Points | Criterion |
|---|---|
| 2 | Ran `pipeline.ps1` and observed `gizmo $0.00` BEFORE editing (reproduced the failure) |
| 2 | Exonerated `format.ps1` with evidence (it formats 0.00 correctly; 0 is the real input, not a format bug) |
| 3 | Root cause identified: `Get-TierMultiplier` omits `gold` (drift from `tiers.json`) → `$null` → `price * $null = 0` in `pipeline.ps1` |
| 2 | Fix yields `gizmo $30.00`, verified by rerunning the pipeline |
| 1 | Robustness: unknown tier made to fail loudly instead of silently zeroing (or explicitly flags the `$null`→0 coercion trap) |

Failure smells: editing `Format-Money` to special-case 0; adding `gold` with a
guessed multiplier without finding `tiers.json`; declaring done without
rerunning the pipeline; missing the silent `$null`→0 coercion entirely.
