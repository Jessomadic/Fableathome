---
name: security-review
description: Focused security audit of code or a diff — authentication/authorization gaps, injection (SQL/command/path/template), secret handling and exposure, unsafe deserialization, SSRF, and missing input validation at trust boundaries. Reports concrete, exploitable findings with file:line evidence and a severity, or states clearly that none were found. Use PROACTIVELY before shipping code that handles untrusted input, credentials, authorization, or external requests.
---

# /security-review — find the exploitable, prove it, rank it

A security review that lists generic best practices is noise. This produces
specific findings tied to real code paths, each with the input that triggers it,
or an explicit "no significant issues found."

## Step 1 — Map the trust boundaries

Identify where untrusted data enters (request params, headers, files, env,
third-party responses) and where sensitive actions happen (DB queries, shell/OS
calls, file paths, auth checks, outbound requests, deserialization, secret
use). The findings live on the paths connecting the two. Read those paths in
the actual code — do not audit from file names.

## Step 2 — Check each class against the code

For each boundary, check the classes that apply:

- **AuthZ/AuthN**: is every sensitive action gated by an ownership/role check
  that cannot be skipped by changing an ID (IDOR), a missing check, or a
  client-trusted flag?
- **Injection**: is untrusted data ever concatenated into SQL, a shell command,
  a file path (traversal), an HTML/template context, or an eval?
- **Secrets**: are credentials hard-coded, logged, returned in errors, or
  committed? Are they read from a safe source?
- **SSRF / outbound**: can a user control a URL the server then fetches?
- **Deserialization / input validation**: is untrusted input parsed by an
  unsafe deserializer or used without validation at the boundary?

## Step 3 — Confirm exploitability before reporting

For each candidate, state the concrete input or sequence that triggers it and
the impact. Discard anything you cannot connect to a real reachable path — a
theoretical issue behind an effective guard is not a finding. Trace it, don't
assume it.

## Step 4 — Report ranked findings with evidence

Output each finding as: **severity** (critical/high/medium/low) — **location**
(file:line) — **the defect** — **the triggering input** — **the fix**. Order by
severity. If nothing survived Step 3, say so plainly rather than padding. For an
action's blast radius (as opposed to a code flaw), route to the **fable-warden**
agent instead.
