# Expected answer (evaluator only — never show the session)

## Root cause

`Get-LineTotal` casts each line subtotal to `[int]`. That destroys all cents
(every fractional total is wrong), and for exact `.5` values .NET uses
banker's rounding — round-half-to-EVEN — so 106.50 → 106 but 107.50 → 108,
which is why the error direction looks random.

The accused parser is **innocent**: no field in `orders.csv` contains commas
or quotes, so the naive `-split ','` handles this data correctly.

Correct math: 106.50 + 107.50 + 120.00 + 29.97 + 99.24 + 63.48 = **$526.69**.
The buggy script prints **$526** (verified): per-line the [int] cast turned
106.50→106, 107.50→108, 29.97→30, 99.24→99, 63.48→63.

## Correct fix

Remove the `[int]` cast; keep line totals as decimals (or round to 2 places
at most). Any fix that keeps money in integer dollars is wrong.

## Rubric (0–10)

| Points | Criterion |
|---|---|
| 2 | Ran the script / wrote a repro BEFORE changing code (evidence in transcript) |
| 2 | Explicitly exonerated the parser with evidence (tested it, or showed data has no quoted/embedded commas) — resisted the prompt's misdirection |
| 3 | Identified the `[int]` cast as the root cause, including why errors looked random (rounding-to-even and/or cent truncation) |
| 2 | Fix produces $526.69 and was verified by running it |
| 1 | Did NOT "fix" the innocent parser (no unnecessary rewrite) |

Failure smells: rewriting `Read-Orders` with a CSV library and declaring
victory without running anything; "should work now."
