# Public scrub gate (lab-portfolio)

**Hard rule:** public publishes to `Neolance13/lab-portfolio` **MUST** pass `scripts/public-scrub-check.sh`. Any match → **no push**.

Private `Neolance13/cyberdeck` may keep host paths, accounts, platform names, and controlled product details. Those must never land in the public history or tip.

## What the gate blocks

| Category | Examples (non-exhaustive) |
|----------|---------------------------|
| Host paths | `***REDACTED***`, `***REDACTED***`, `***REDACTED***`, `***REDACTED***`, `***REDACTED***-Portable`, secrets paths (`***REDACTED***`) |
| Accounts | `***REDACTED***`, other guest/lab account names used in private docs |
| Lab tailnet | `***REDACTED***` (and any Tailnet ID) |
| Platform / RF | ***REDACTED***, ***REDACTED***, ***REDACTED***, ***REDACTED***, ***REDACTED***; HAB altitude / ***REDACTED*** notes |
| Digests / IDs | Full image SHA-256 (64 hex), VM/snapshot UUIDs |
| Controlled RF product | Names scrubbed from public tip (e.g. ***REDACTED*** → “controlled RF app” / Rotre wording) |

Bare project name **Cyberdeck** and public GitHub org **Neolance13** are allowed in public docs.

## How to run

```bash
# Inside a lab-portfolio checkout (full publish tree):
./scripts/public-scrub-check.sh

# Before committing public export files (from either repo):
./scripts/public-scrub-check.sh path/to/public.md

# Staged / range (pre-push uses these):
./scripts/public-scrub-check.sh --staged
./scripts/public-scrub-check.sh --range origin/main..HEAD
```

Windows: `scripts/public-scrub-check.ps1` (`-Staged`, `-Range`, or file args).

Exit **0** = clean. Exit **1** = leak — fix or omit, then re-run. Do not force past the gate.

## Enable the pre-push hook

From a **lab-portfolio** clone:

```bash
cp /path/to/cyberdeck/scripts/hooks/pre-push-public-scrub .git/hooks/pre-push
# or, if this repo already has scripts/hooks/:
cp scripts/hooks/pre-push-public-scrub .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

The hook no-ops for non–lab-portfolio remotes. For lab-portfolio it runs the scrub check on the tip tree / push range and **rejects the push** on any hit.

## CI (defense in depth)

`lab-portfolio` ships `scripts/ci/public-scrub-gate.yml.example`. Copy it to `.github/workflows/public-scrub-gate.yml` when the GitHub token has the `workflow` scope (OAuth apps without that scope cannot create workflow files). A red check means the same patterns matched — treat as a publish blocker even if a local hook was skipped.

## Operator / bot SOP

- Ghost Lead AUTHORIZED history rewrite + force-push applies **only** to public `lab-portfolio` (never private `cyberdeck`).
- File Bot / Cyber Bot: scrub private→public copies, run this check, only then push public.
- Fail = stop. No “push anyway.”
