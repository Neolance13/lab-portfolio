#!/usr/bin/env bash
# public-scrub-check.sh — exit non-zero if scrub-forbidden patterns appear in
# content destined for the PUBLIC Neolance13/lab-portfolio publish.
#
# Usage:
#   scripts/public-scrub-check.sh                 # lab-portfolio: scan publish tree
#   scripts/public-scrub-check.sh FILE [FILE...]  # scan listed paths
#   scripts/public-scrub-check.sh --staged         # git staged files
#   scripts/public-scrub-check.sh --range A..B     # files changed in range
#   scripts/public-scrub-check.sh --stdin-files    # paths on stdin (hook helper)
#
# Specific deny-list terms are NOT stored in this public repo. They are loaded
# at runtime from a private term file, looked up in this order:
#   1. $SCRUB_TERMS_FILE (if set and non-empty)
#   2. <repo root>/scrub-terms.local (gitignored; never commit it)
# Format: one regex per line; blank lines and lines starting with # are ignored.
# The check FAILS CLOSED (exit 2) if the file is missing, unreadable, tracked by
# git, contains an invalid pattern, or has zero usable patterns.
# Hits are reported as file:line plus a category; matched text and the term
# list itself are never printed.
#
# Exit 0 = clean. Exit 1 = leak match (do NOT push public).
# Exit 2 = usage / configuration error (term list missing or invalid) — treat as FAIL.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

die_config() {
  echo "public-scrub-check: FAIL (closed) — $*" >&2
  echo "  Provide the private term list via SCRUB_TERMS_FILE=/path/to/list" >&2
  echo "  or a gitignored scrub-terms.local at the repo root. See docs/PUBLIC-SCRUB-GATE.md." >&2
  exit 2
}

is_lab_portfolio() {
  local url name
  name="$(basename "$ROOT")"
  [[ "$name" == "lab-portfolio" || "$name" == "lab-portfolio-rewrite" ]] && return 0
  url="$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)"
  [[ "$url" == *lab-portfolio* ]] && return 0
  return 1
}

# ---------------------------------------------------------------------------
# Generic (non-sensitive) pattern classes — safe to keep in public.
# ---------------------------------------------------------------------------
generic_sha256='[0-9a-fA-F]{64}'
generic_uuid='[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
generic_credential='-----BEGIN ([A-Z]+ )?PRIVATE KEY|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{22,}|xox[abprs]-[A-Za-z0-9-]{10,}|tskey-[A-Za-z0-9-]{10,}'
generic_mac='\b([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}\b'
generic_email='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
# Emails allowed in public docs (GitHub noreply, RFC 2606 example domains).
email_allow='@users\.noreply\.github\.com$|@example\.(com|org|net)$'

# ---------------------------------------------------------------------------
# Private term list (runtime, fail closed)
# ---------------------------------------------------------------------------
TERMS_SRC=""
if [[ -n "${SCRUB_TERMS_FILE:-}" ]]; then
  TERMS_SRC="$SCRUB_TERMS_FILE"
  TERMS_ORIGIN="SCRUB_TERMS_FILE"
else
  TERMS_SRC="$ROOT/scrub-terms.local"
  TERMS_ORIGIN="repo-root scrub-terms.local"
fi

[[ -e "$TERMS_SRC" ]] || die_config "private term list not found ($TERMS_ORIGIN)."
[[ -f "$TERMS_SRC" ]] || die_config "private term list is not a regular file ($TERMS_ORIGIN)."
[[ -r "$TERMS_SRC" ]] || die_config "private term list is not readable ($TERMS_ORIGIN)."

TERMS_ABS="$(cd "$(dirname "$TERMS_SRC")" && pwd)/$(basename "$TERMS_SRC")"

# A term file tracked inside this (public) repo would itself be a leak.
if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  case "$TERMS_ABS" in
    "$ROOT"/*)
      rel="${TERMS_ABS#"$ROOT"/}"
      if git -C "$ROOT" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
        die_config "private term list is TRACKED by git in this repo; remove it from the index."
      fi
      if ! git -C "$ROOT" check-ignore -q -- "$rel" 2>/dev/null; then
        echo "public-scrub-check: WARNING — term list inside the repo is not gitignored; add it to .gitignore." >&2
      fi
      ;;
  esac
fi

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT
TERMS="$TMPD/terms"

# Strip CR, comments, blank lines and surrounding whitespace.
if ! sed -e 's/\r$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -- "$TERMS_SRC" \
     | { grep -v -e '^#' -e '^$' || true; } >"$TERMS"; then
  die_config "could not read private term list ($TERMS_ORIGIN)."
fi
NTERMS="$(wc -l <"$TERMS" | tr -d ' ')"
[[ "$NTERMS" -gt 0 ]] || die_config "private term list has zero usable patterns ($TERMS_ORIGIN)."

if command -v rg >/dev/null 2>&1; then USE_RG=1; else USE_RG=0; fi

# Validate every pattern; report only the line index, never the pattern.
idx=0
while IFS= read -r pat; do
  idx=$((idx + 1))
  rc=0
  if [[ "$USE_RG" -eq 1 ]]; then
    rg -q -i -e "$pat" -- /dev/null >/dev/null 2>&1 || rc=$?
  else
    grep -q -i -E -e "$pat" -- /dev/null >/dev/null 2>&1 || rc=$?
  fi
  [[ "$rc" -le 1 ]] || die_config "pattern #$idx (counting usable lines) in the private term list is not a valid regex."
done <"$TERMS"

usage() {
  echo "Usage: $0 [--staged|--range A..B|--stdin-files|FILE...]" >&2
  echo "  In private cyberdeck: pass --staged, --range, or explicit public export files." >&2
  echo "  In lab-portfolio: bare invocation scans the publish tree." >&2
  exit 2
}

should_skip_path() {
  # Never scan the private term file itself (it is outside the public tree or gitignored).
  [[ "$1" == "$TERMS_ABS" ]]
}

is_binaryish() {
  case "$1" in
    *.png|*.jpg|*.jpeg|*.gif|*.webp|*.ico|*.pdf|*.zip|*.gz|*.xz|*.7z|*.bin|*.o|*.a|*.so|*.vdi|*.ova|*.iso)
      return 0 ;;
  esac
  return 1
}

collect_default_lab_portfolio() {
  find "$ROOT" -type f \
    ! -path '*/.git/*' \
    ! -path '*/node_modules/*' \
    \( -name '*.md' -o -name '*.txt' -o -name '*.yml' -o -name '*.yaml' \
       -o -name '*.sh' -o -name '*.ps1' -o -name '*.py' -o -name '*.json' \
       -o -name '*.toml' -o -name '*.cfg' -o -name '*.conf' -o -name '*.example' \)
}

collect_files() {
  local mode="${1:-}"
  shift || true
  case "$mode" in
    --staged)
      git -C "$ROOT" diff --cached --name-only --diff-filter=ACMR
      ;;
    --range)
      local range="${1:-}"
      [[ -n "$range" ]] || usage
      git -C "$ROOT" diff --name-only --diff-filter=ACMR "$range"
      ;;
    --stdin-files)
      cat
      ;;
    "")
      collect_default_lab_portfolio
      ;;
    *)
      printf '%s\n' "$mode" "$@"
      ;;
  esac
}

MODE="${1:-}"
RAW=()
if [[ "$MODE" == "--staged" ]]; then
  mapfile -t RAW < <(collect_files --staged)
elif [[ "$MODE" == "--range" ]]; then
  [[ -n "${2:-}" ]] || usage
  mapfile -t RAW < <(collect_files --range "${2:-}")
elif [[ "$MODE" == "--stdin-files" ]]; then
  mapfile -t RAW < <(collect_files --stdin-files)
elif [[ $# -gt 0 ]]; then
  mapfile -t RAW < <(collect_files "$@")
else
  if ! is_lab_portfolio; then
    echo "public-scrub-check: private repo — pass --staged, --range, or file list (refusing full-tree scan)." >&2
    usage
  fi
  mapfile -t RAW < <(collect_default_lab_portfolio)
fi

declare -A SEEN=()
SCAN=()
for f in "${RAW[@]:-}"; do
  [[ -z "$f" ]] && continue
  if [[ "$f" != /* ]]; then
    f="$ROOT/$f"
  fi
  [[ -f "$f" ]] || continue
  should_skip_path "$f" && continue
  is_binaryish "$f" && continue
  [[ -n "${SEEN[$f]:-}" ]] && continue
  SEEN[$f]=1
  SCAN+=("$f")
done

if [[ ${#SCAN[@]} -eq 0 ]]; then
  echo "public-scrub-check: no files to scan (ok; private term list loaded: $NTERMS pattern(s))"
  exit 0
fi

REPORT="$TMPD/report"
: >"$REPORT"

# run_scan CATEGORY  (patterns via -f FILE or -e PATTERN). Appends "file:line [category]".
# Uses --only-matching so allowlists can be applied to the match; the match is then dropped.
run_scan() {
  local category="$1"; shift
  local out="$TMPD/out" rc=0
  if [[ "$USE_RG" -eq 1 ]]; then
    rg -i -n -o --no-heading --with-filename --no-config "$@" -- "${SCAN[@]}" >"$out" 2>/dev/null || rc=$?
  else
    grep -i -n -o -H -E "$@" -- "${SCAN[@]}" >"$out" 2>/dev/null || rc=$?
  fi
  if [[ "$rc" -gt 1 ]]; then
    echo "public-scrub-check: FAIL (closed) — scanner error during '$category' check." >&2
    exit 2
  fi
  [[ "$rc" -eq 0 ]] || return 0
  # out lines: path:line:match
  local path line match
  while IFS= read -r rec; do
    path="${rec%%:*}"; rec="${rec#*:}"
    line="${rec%%:*}"; match="${rec#*:}"
    if [[ "$category" == "email-address" ]] && printf '%s\n' "$match" | grep -qiE -- "$email_allow"; then
      continue
    fi
    printf '%s:%s [%s]\n' "${path#"$ROOT"/}" "$line" "$category" >>"$REPORT"
  done <"$out"
}

run_scan "private-term"     -f "$TERMS"
run_scan "sha256-shape"     -e "$generic_sha256"
run_scan "uuid-shape"       -e "$generic_uuid"
run_scan "credential-shape" -e "$generic_credential"
run_scan "mac-address"      -e "$generic_mac"
run_scan "email-address"    -e "$generic_email"

if [[ -s "$REPORT" ]]; then
  echo "PUBLIC SCRUB GATE FAILED — forbidden patterns found (file:line [category]; matched text not shown):" >&2
  sort -u "$REPORT" >&2
  echo "" >&2
  echo "Do NOT push to public lab-portfolio. Scrub or omit the matching content." >&2
  echo "See docs/PUBLIC-SCRUB-GATE.md." >&2
  exit 1
fi

echo "public-scrub-check: PASS (${#SCAN[@]} file(s) scanned; private term list loaded: $NTERMS pattern(s))"
exit 0
