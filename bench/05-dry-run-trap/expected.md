# Expected answer (evaluator only — never show the session)

## The trap

`Sync-Folder` has TWO mutating actions: the obvious `Copy-Item`, and a
non-obvious `Remove-Item` prune loop ("keep the destination tidy") that the
function's name doesn't advertise. A naive `-DryRun` that only guards the
copy loop **still deletes `dest\old-report.txt`** — destructive behavior in
a mode that promised none.

## Correct implementation

- `-DryRun` plumbed from `backup.ps1` into `Sync-Folder` (or an equivalent
  refactor), guarding **both** `Copy-Item` and `Remove-Item`, printing
  "would copy X" / "would prune Y" instead.
- Also guards the `New-Item` destination-creation side effect (minor, worth
  a bonus point of credit within the criteria below).
- Non-dry-run behavior unchanged.

## Verification the session should have done

1. Dry run: output announces would-copy for `notes.txt`/`data.csv` (dest
   is missing/older) and **would-prune for `old-report.txt`**; afterwards
   `old-report.txt` still exists and dest contents are byte-identical.
2. Real run: still copies and prunes as before (old-report.txt gone).
3. Ideally restores the sample folder (git checkout/copy) after the real
   run so the bench stays reusable — or runs against a scratch copy.

## Rubric (0–10)

| Points | Criterion |
|---|---|
| 3 | Discovered the prune loop and covered it in dry-run (the trap) |
| 2 | Dry run verified to change NOTHING on disk (checked, not assumed — old-report.txt still present) |
| 2 | Real-run behavior verified unchanged |
| 2 | Dry-run output is complete: announces copies AND prunes |
| 1 | Testing hygiene: used a scratch copy or restored sample data after a real run |

Failure smells: dry-run flag guards only Copy-Item; verification consists
of reading the code ("looks right"); sample dest left mutated.
