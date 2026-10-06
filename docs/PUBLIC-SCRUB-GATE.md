# Public scrub gate (lab-portfolio)

**Hard rule:** publishes to the public `Neolance13/lab-portfolio` repository **MUST** pass `scripts/public-scrub-check.sh` (or the Windows twin `scripts/public-scrub-check.ps1`). Any match → **no push**.

The private `Neolance13/cyberdeck` repository may keep host paths, lab accounts, platform names, and controlled product details. Those must never land in the public history or tip.

## What runs

1. **Local scrub scripts** (`scripts/public-scrub-check.sh` / `.ps1`) — primary gate before any public push.
2. **Optional pre-push hook** (`scripts/hooks/pre-push-public-scrub`) — rejects a push to a lab-portfolio remote when the scrub check fails.
3. **Optional CI workflow** — copy `scripts/ci/public-scrub-gate.yml.example` to `.github/workflows/public-scrub-gate.yml` when the GitHub token has the `workflow` scope. A red check is a publish blocker even if a local hook was skipped.
4. **Defense in depth (manual / Sec Bot):** secret scanners such as **gitleaks** and **trufflehog** over the tip (and, for history rewrites, over all refs). They do not replace the scrub scripts.

## Categories checked

| Category | How it is checked |
|----------|-------------------|
| Credentials / secrets | Generic shapes (private-key PEM headers, common cloud/API token prefixes) baked into the scripts |
| Digests / IDs | Generic SHA-256 (64 hex) and UUID shapes baked into the scripts |
| Network identifiers | Generic MAC and email shapes baked into the scripts (plus a small allowlist for GitHub noreply and RFC 2606 example domains) |
| Names, accounts, lab tailnet, platform / RF products, controlled RF / HAB specifics | **Private deny-list**, loaded at runtime (see below) |
| Host drive paths, secrets-path fragments, lab IPs / MAC OUIs | **Private deny-list**, loaded at runtime |

Bare project name **Cyberdeck** and public GitHub org / user **Neolance13** are allowed in public docs.

## Private term list (runtime, fail closed)

**Specific deny-list terms are not stored in this public repository.** They live only in the private cyberdeck tree and are loaded at runtime in this order:

1. Environment variable `SCRUB_TERMS_FILE` (absolute or relative path to a term file), if set and non-empty.
2. A **gitignored** file `scrub-terms.local` at the repository root (never commit it; `*.scrub-terms.local` is also ignored).

**Format:** one regex per line. Blank lines and lines whose first non-whitespace character is `#` are ignored. Matching is **case-insensitive**.

**Fail closed:** if the term file is missing, unreadable, tracked by git inside this repo, contains an invalid pattern, or has **zero** usable patterns, the script exits **non-zero** (configuration failure) with a clear message and **does not** print the term list. On content hits it prints `file:line [category]` only — never the matched text and never the term list.

Operators and bots obtain the list from the private cyberdeck path documented there (for example by exporting `SCRUB_TERMS_FILE` or by copying the file to a local `scrub-terms.local`).

## How to run

```bash
# Inside a lab-portfolio checkout (full publish tree):
export SCRUB_TERMS_FILE=/path/to/private/scrub-terms.list   # or place scrub-terms.local at repo root
./scripts/public-scrub-check.sh

# Before committing public export files (from either repo):
./scripts/public-scrub-check.sh path/to/public.md

# Staged / range (pre-push uses these):
./scripts/public-scrub-check.sh --staged
./scripts/public-scrub-check.sh --range origin/main..HEAD
```

Windows: `scripts/public-scrub-check.ps1` (`-Staged`, `-Range`, or file args). Same `SCRUB_TERMS_FILE` / `scrub-terms.local` rules.

Exit **0** = clean. Exit **1** = content leak — fix or omit, then re-run. Exit **2** = configuration / term-list failure (fail closed). Do not force past the gate.

## Enable the pre-push hook

From a **lab-portfolio** clone (with a private term list available via env or `scrub-terms.local`):

```bash
cp /path/to/cyberdeck/scripts/hooks/pre-push-public-scrub .git/hooks/pre-push
# or, if this repo already has scripts/hooks/:
cp scripts/hooks/pre-push-public-scrub .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

The hook no-ops for non–lab-portfolio remotes. For lab-portfolio it runs the scrub check on the tip tree / push range and **rejects the push** on any hit or configuration failure.

## Operator / bot SOP

- History rewrite + force-push of public `lab-portfolio` requires explicit operator approval via Ghost Lead and a Sec Bot gate. Never rewrite private `cyberdeck`.
- File Bot / Cyber Bot: scrub private→public copies, ensure the private term list is available, run this check, only then push public.
- Fail = stop. No “push anyway.”
