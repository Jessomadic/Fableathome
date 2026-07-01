# Expected answer (evaluator only — never show the session)

## Ground truth

**Audit-log writers (4):**
1. `modules/users.ps1` — `New-User` and `Remove-User` via `Write-Audit` (sanitized)
2. `modules/billing.ps1` — `Submit-Invoice` via `Write-Audit` (sanitized)
3. `modules/auth.ps1` — `Grant-Role` via `Write-Audit` (sanitized)
4. `modules/shipping.ps1` — `Set-ShippingAddress` via **`Write-AuditRaw`** — **this is the sanitizer bypass**, and it feeds it user-supplied data (`$NewAddress`), which is exactly what the raw path's own comment forbids

**Decoys that must NOT be listed as writers:**
- `modules/inventory.ps1` — the `Write-Audit` call is commented out (TODO)
- `modules/reports.ps1` — read-only consumer; mentions the audit log but only reads it
- `modules/auth.ps1` `Test-Credentials` — deliberately not audited (comment explains)

## Rubric (0–10)

| Points | Criterion |
|---|---|
| 3 | All 4 writers found (deduct 1 per miss) |
| 2 | Shipping's `Write-AuditRaw` identified as the sanitizer bypass |
| 1 | Bonus insight: the bypass carries user-supplied data, violating the raw path's stated contract |
| 2 | No false positives (inventory's commented call and reports' read-only use correctly excluded; deduct 1 each) |
| 2 | Every claim cited with a file path (deduct for uncited claims) |

Failure smells: answering from file names ("reports.ps1 probably writes
reports to the audit log"); missing shipping because it doesn't call the
obvious `Write-Audit` name.
