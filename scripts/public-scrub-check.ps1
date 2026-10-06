# public-scrub-check.ps1 — Windows twin of public-scrub-check.sh
# Exit 1 on scrub-forbidden pattern match in paths destined for public lab-portfolio.
param(
  [switch]$Staged,
  [string]$Range,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Paths
)
$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
$Patterns = @(
  '***REDACTED***', '***REDACTED***', '***REDACTED***', '***REDACTED***',
  '***REDACTED***', '***REDACTED***',
  '***REDACTED***', '***REDACTED***',
  '***REDACTED***', 'Secrets\\***REDACTED***', 'Secrets/***REDACTED***',
  '***REDACTED***', '***REDACTED***',
  '***REDACTED***', '***REDACTED***', '***REDACTED***', '***REDACTED***', '***REDACTED***',
  '***REDACTED***', '***REDACTED***', '***REDACTED***',
  '***REDACTED***', '***REDACTED***',
  '[0-9a-fA-F]{64}',
  '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
)
$Skip = @('public-scrub-check.sh','public-scrub-check.ps1','PUBLIC-SCRUB-GATE.md','pre-push-public-scrub','public-scrub-gate.yml')
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
    $files = Get-ChildItem -Path $Root -Recurse -File -Include *.md,*.txt,*.yml,*.yaml,*.sh,*.ps1,*.py |
      Where-Object { $_.FullName -notmatch '\\.git\\' } |
      ForEach-Object { $_.FullName }
  } else {
    Write-Error 'private repo: pass -Staged, -Range, or explicit files'
  }
}
$joined = ($Patterns -join '|')
$rx = [regex]::new($joined, 'IgnoreCase')
$hits = @()
foreach ($f in $files) {
  $full = if ([IO.Path]::IsPathRooted($f)) { $f } else { Join-Path $Root $f }
  if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
  $base = Split-Path $full -Leaf
  if ($Skip -contains $base) { continue }
  $text = Get-Content -LiteralPath $full -Raw -ErrorAction SilentlyContinue
  if ($null -eq $text) { continue }
  foreach ($m in $rx.Matches($text)) {
    $hits += "${full}: matched '$($m.Value)'"
  }
}
if ($hits.Count -gt 0) {
  Write-Host 'PUBLIC SCRUB GATE FAILED — forbidden patterns found:'
  $hits | ForEach-Object { Write-Host $_ }
  exit 1
}
Write-Host "public-scrub-check: PASS ($($files.Count) path(s))"
exit 0
