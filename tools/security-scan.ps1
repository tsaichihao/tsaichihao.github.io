[CmdletBinding()]
param(
  [switch]$Staged
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

$patterns = [ordered]@{
  "Private key" = "-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"
  "GitHub token" = "(?:ghp|gho|ghu|ghs|ghr|github_pat)_[A-Za-z0-9_]{20,}"
  "AWS access key" = "(?:AKIA|ASIA)[A-Z0-9]{16}"
  "Google API key" = "AIza[0-9A-Za-z_-]{35}"
  "OpenAI API key" = "sk-[A-Za-z0-9_-]{20,}"
  "Bearer token" = "Bearer\s+[A-Za-z0-9._~+/-]{24,}={0,2}"
  "Email address" = "(?i)(?![A-Za-z0-9._%+-]+@users\.noreply\.github\.com)[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"
  "Taiwan mobile" = "(?<!\d)09\d{8}(?!\d)"
}

if ($Staged) {
  $content = (& git -C $repoRoot diff --cached --no-ext-diff --unified=0 -- .) -join "`n"
} else {
  $files = & git -C $repoRoot ls-files
  $content = ($files | ForEach-Object {
    $path = Join-Path $repoRoot $_
    if ((Get-Item -LiteralPath $path).Length -le 5MB) {
      Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
    }
  }) -join "`n"
}

$problems = @()
foreach ($entry in $patterns.GetEnumerator()) {
  if ([regex]::IsMatch($content, $entry.Value)) {
    $problems += $entry.Key
  }
}

$blockedFiles = & git -C $repoRoot ls-files |
  Where-Object {
    $_ -match "(?i)(^|/)\.env($|\.)|\.p(?:em|12|fx)$|\.key$|original\.(?:jpe?g|png|webp)$"
  }
if ($blockedFiles) {
  $problems += "Blocked sensitive filename"
}

if ($problems) {
  Write-Error ("Security scan failed: " + (($problems | Sort-Object -Unique) -join ", "))
  exit 1
}

Write-Host "Security scan passed."
