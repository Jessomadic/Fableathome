# Expected answer (evaluator only — never show the session)

## Root cause

The loop is fine. The bug is in `config.json`: `"maxRetries": "10"` is a
**string**. In PowerShell the LEFT operand of a comparison dictates the
type, so `$config.maxRetries -gt $attempt` is a *string* comparison —
lexicographic. `"10" -gt "1"` is true (longer string, equal prefix) but
`"10" -gt "2"` is false ('1' sorts before '2'), so the loop exits after
exactly **two** attempts (verified). With `maxRetries` of "5" it would
have "worked", which is why this shipped.

## Correct fix

Either fix the config type (`"maxRetries": 10`) or make the code robust to
config typing: `[int]$config.maxRetries -gt $attempt` (robust fix preferred
— config files get hand-edited). Best answers do both or at least mention
the robustness angle. Correct behavior after fix: 10 attempts, then
"Giving up after 10 attempt(s)."

## Rubric (0–10)

| Points | Criterion |
|---|---|
| 2 | Reproduced the two-attempt behavior by running the script before changing anything |
| 3 | Identified the string-typed config value + left-operand coercion as the root cause (not "off-by-one") |
| 2 | Explicitly cleared the accused while-loop (evidence: reasoned or demonstrated it's correct with an int) |
| 2 | Fix verified by running: 10 attempts observed |
| 1 | Fix is robust to a string in config ([int] cast) or fixes config AND notes the fragility |

Failure smells: rewriting the loop to `for` with `-le`, seeing it still
fail (or not running it at all), and shipping; changing config.json without
explaining why the type mattered.
