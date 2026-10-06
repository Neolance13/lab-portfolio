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
# Exit 0 = clean. Exit 1 = leak match (do NOT push public). Exit 2 = usage/error.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

is_lab_portfolio() {
  local url name
  name="$(basename "$ROOT")"
  [[ "$name" == "lab-portfolio" || "$name" == "lab-portfolio-rewrite" ]] && return 0
  url="$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)"
  [[ "$url" == *lab-portfolio* ]] && return 0
  return 1
}

# Forbidden patterns (public). Keep in sync with Docs/PUBLIC-SCRUB-GATE.md + CI.
# NOTE: bare "Cyberdeck" (project name) and public GitHub org Neolance13 are OK.
build_pattern() {
  cat << 'PAT'
***REDACTED***
***REDACTED***
***REDACTED***
***REDACTED***
***REDACTED***
***REDACTED***
***REDACTED***
***REDACTED***
***REDACTED***-Portable
***REDACTED***-Portable
***REDACTED***
Secrets\\***REDACTED***
Secrets/***REDACTED***
***REDACTED***
***REDACTED***
***REDACTED***
***REDACTED***
***REDACTED***
***REDACTED***
***REDACTED***
***REDACTED***
***REDACTED***
***REDACTED***
50,?000[[:space:]]*ft
15,?240[[:space:]]*m
[0-9a-fA-F]{64}
[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}
PAT
}

usage() {
  echo "Usage: $0 [--staged|--range A..B|--stdin-files|FILE...]" >&2
  echo "  In private cyberdeck: pass --staged, --range, or explicit public export files." >&2
  echo "  In lab-portfolio: bare invocation scans the publish tree." >&2
  exit 2
}

should_skip_path() {
  local f="$1"
  case "$f" in
    */public-scrub-check.sh|*/public-scrub-check.ps1|*/PUBLIC-SCRUB-GATE.md|\
    */pre-push-public-scrub|*/public-scrub-gate.yml|*PUBLIC-SCRUB-GATE*)
      return 0
      ;;
  esac
  return 1
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
  echo "public-scrub-check: no files to scan (ok)"
  exit 0
fi

ALT="$(build_pattern | paste -sd'|')"
REPORT="$(mktemp)"
trap 'rm -f "$REPORT"' EXIT

HITS=0
if command -v rg >/dev/null 2>&1; then
  if rg -n -i -e "$ALT" --no-heading -- "${SCAN[@]}" >"$REPORT" 2>/dev/null; then
    HITS=1
  fi
else
  if grep -n -i -E -e "$ALT" -- "${SCAN[@]}" >"$REPORT" 2>/dev/null; then
    HITS=1
  fi
fi

if [[ "$HITS" -eq 1 && -s "$REPORT" ]]; then
  echo "PUBLIC SCRUB GATE FAILED — forbidden patterns found:" >&2
  cat "$REPORT" >&2
  echo "" >&2
  echo "Do NOT push to public lab-portfolio. Scrub or omit the matching content." >&2
  echo "See Docs/PUBLIC-SCRUB-GATE.md (cyberdeck) or docs/PUBLIC-SCRUB-GATE.md (lab-portfolio)." >&2
  exit 1
fi

echo "public-scrub-check: PASS (${#SCAN[@]} file(s) scanned)"
exit 0
