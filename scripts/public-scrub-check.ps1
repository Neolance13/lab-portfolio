# public-scrub-check.ps1 — Windows twin of public-scrub-check.sh
# Exit 1 on scrub-forbidden pattern match in paths destined for public lab-portfolio.
#
# Specific deny-list terms are NOT stored in this public repo. They are loaded at
# runtime from a private term file, looked up in this order:
#   1. $env:SCRUB_TERMS_FILE (if set and non-empty)
#   2. <repo root>\scrub-terms.local (gitignored; never commit it)
# Format: one regex per line; blank lines and lines starting with # are ignored.
# FAILS CLOSED (exit 2) if the file is missing, unreadable, tracked by git, has an
# invalid pattern, or has zero usable patterns. Hits are reported as file:line plus
# a category; matched text and the term list itself are never printed.
#
# Exit 0 = clean. Exit 1 = leak match. Exit 2 = usage / configuration error (FAIL).
param(
  [switch]$Staged,
  [string]$Range,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Paths
)
$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Fail-Closed([string]$msg) {
  [Console]::Error.WriteLine("public-scrub-check: FAIL (closed) — $msg")
  [Console]::Error.WriteLine('  Provide the private term list via $env:SCRUB_TERMS_FILE or a gitignored scrub-terms.local at the repo root. See docs/PUBLIC-SCRUB-GATE.md.')
  exit 2
}

# --- Generic (non-sensitive) pattern classes — safe to keep in public ---
$Generic = [ordered]@{
  'sha256-shape'     = '[0-9a-fA-F]{64}'
  'uuid-shape'       = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
  'credential-shape' = '-----BEGIN ([A-Z]+ )?PRIVATE KEY|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{22,}|xox[abprs]-[A-Za-z0-9-]{10,}|tskey-[A-Za-z0-9-]{10,}'
  'mac-address'      = '\b([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}\b'
  'email-address'    = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
}
$EmailAllow = [regex]::new('@users\.noreply\.github\.com$|@example\.(com|org|net)$', 'IgnoreCase')

# --- Private term list (runtime, fail closed) ---
if (-not [string]::IsNullOrWhiteSpace($env:SCRUB_TERMS_FILE)) {
  $TermsSrc = $env:SCRUB_TERMS_FILE; $TermsOrigin = 'SCRUB_TERMS_FILE'
} else {
  $TermsSrc = Join-Path $Root 'scrub-terms.local'; $TermsOrigin = 'repo-root scrub-terms.local'
}
if (-not (Test-Path -LiteralPath $TermsSrc)) { Fail-Closed "private term list not found ($TermsOrigin)." }
if (-not (Test-Path -LiteralPath $TermsSrc -PathType Leaf)) { Fail-Closed "private term list is not a regular file ($TermsOrigin)." }
try {
  $TermsAbs = (Resolve-Path -LiteralPath $TermsSrc).Path
  $rawLines = [IO.File]::ReadAllLines($TermsAbs)
} catch {
  Fail-Closed "private term list is not readable ($TermsOrigin)."
}

# A term file tracked inside this (public) repo would itself be a leak.
$rootPrefix = $Root.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
if ($TermsAbs.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
  $rel = $TermsAbs.Substring($rootPrefix.Length)
  & git -C $Root ls-files --error-unmatch -- $rel *> $null
  if ($LASTEXITCODE -eq 0) { Fail-Closed 'private term list is TRACKED by git in this repo; remove it from the index.' }
  & git -C $Root check-ignore -q -- $rel *> $null
  if ($LASTEXITCODE -ne 0) { [Console]::Error.WriteLine('public-scrub-check: WARNING — term list inside the repo is not gitignored; add it to .gitignore.') }
}

$Terms = @()
foreach ($l in $rawLines) {
  $t = $l.Trim()
  if ($t.Length -eq 0 -or $t.StartsWith('#')) { continue }
  $Terms += $t
}
if ($Terms.Count -eq 0) { Fail-Closed "private term list has zero usable patterns ($TermsOrigin)." }
$i = 0
foreach ($t in $Terms) {
  $i++
  try { [void][regex]::new($t) } catch { Fail-Closed "pattern #$i (counting usable lines) in the private term list is not a valid regex." }
}

$Checks = [ordered]@{ 'private-term' = [regex]::new(($Terms | ForEach-Object { "(?:$_)" }) -join '|', 'IgnoreCase') }
foreach ($k in $Generic.Keys) { $Checks[$k] = [regex]::new($Generic[$k], 'IgnoreCase') }

# --- Collect files ---
$files = @()
if ($Staged) {
  $files = @(git -C $Root diff --cached --name-only --diff-filter=ACMR)
} elseif ($Range) {
  $files = @(git -C $Root diff --name-only --diff-filter=ACMR $Range)
} elseif ($Paths -and $Paths.Count -gt 0) {
  $files = $Paths
} else {
  $name = Split-Path $Root -Leaf
  $url = ''
  try { $url = git -C $Root remote get-url origin 2>$null } catch {}
  if ($name -match 'lab-portfolio' -or $url -match 'lab-portfolio') {
    $files = Get-ChildItem -Path $Root -Recurse -File -Include *.md,*.txt,*.yml,*.yaml,*.sh,*.ps1,*.py,*.json,*.toml,*.cfg,*.conf,*.example |
      Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' -and $_.FullName -notmatch '[\\/]node_modules[\\/]' } |
      ForEach-Object { $_.FullName }
  } else {
    [Console]::Error.WriteLine('public-scrub-check: private repo — pass -Staged, -Range, or explicit files (refusing full-tree scan).')
    exit 2
  }
}

# --- Scan ---
$hits = New-Object System.Collections.Generic.List[string]
$scanned = 0
foreach ($f in $files) {
  if ([string]::IsNullOrWhiteSpace($f)) { continue }
  $full = if ([IO.Path]::IsPathRooted($f)) { $f } else { Join-Path $Root $f }
  if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
  $full = (Resolve-Path -LiteralPath $full).Path
  if ($full -eq $TermsAbs) { continue }   # never scan the private term file itself
  $scanned++
  $relOut = if ($full.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) { $full.Substring($rootPrefix.Length) } else { $full }
  $lines = @(Get-Content -LiteralPath $full -ErrorAction SilentlyContinue)
  for ($n = 0; $n -lt $lines.Count; $n++) {
    $line = [string]$lines[$n]
    foreach ($cat in $Checks.Keys) {
      foreach ($m in $Checks[$cat].Matches($line)) {
        if ($cat -eq 'email-address' -and $EmailAllow.IsMatch($m.Value)) { continue }
        $hits.Add("${relOut}:$($n + 1) [$cat]")
      }
    }
  }
}
if ($hits.Count -gt 0) {
  Write-Host 'PUBLIC SCRUB GATE FAILED — forbidden patterns found (file:line [category]; matched text not shown):'
  $hits | Sort-Object -Unique | ForEach-Object { Write-Host $_ }
  Write-Host 'Do NOT push to public lab-portfolio. Scrub or omit the matching content. See docs/PUBLIC-SCRUB-GATE.md.'
  exit 1
}
Write-Host "public-scrub-check: PASS ($scanned file(s) scanned; private term list loaded: $($Terms.Count) pattern(s))"
exit 0
