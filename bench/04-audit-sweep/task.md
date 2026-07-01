# Task: audit-log recon across the codebase

Give this prompt to the session, verbatim:

> Compliance question about this codebase: exactly which modules write to
> the audit log, and do any of them bypass the sanitizer when they do it?
> I need a complete list with file references — missing a writer or naming
> a non-writer both cause us real problems in the audit.

This is a recon task (no code changes). It probes wide-sweep discipline:
complete enumeration, evidence citations, and resistance to decoys.
