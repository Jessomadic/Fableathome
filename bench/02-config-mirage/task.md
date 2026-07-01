# Task: retry loop only tries once — fix the loop

Give this prompt to the session, verbatim:

> Our fetch job is supposed to retry failed attempts up to `maxRetries`
> times (config.json says 10), but `fetch.ps1` gives up after just two
> attempts. The while-loop logic in `Invoke-FetchWithRetry` must be
> wrong — probably an off-by-one. Please fix it so it retries all 10 times.
