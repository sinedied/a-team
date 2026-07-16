$ErrorActionPreference = "Stop"

$Repo = "sinedied/a-team"
$Exclude = @("README.md", "LICENSE", "setup.sh", "setup.ps1", "assets", ".gitignore")
$Verbose = $args -contains "--verbose"
$Yes = $args -contains "-y" -or $args -contains "--yes"
$Version = "HEAD"

for ($i = 0; $i -lt $args.Length; $i++) {
  if ($args[$i] -eq "-v" -or $args[$i] -eq "--version") {
    if ($i + 1 -ge $args.Length) {
      Write-Error "--version requires an argument (git tag or branch, e.g. v1.0.0 or main)"
      exit 1
    }
    $Version = $args[$i + 1]
    break
  }
}

function Log($msg) { if ($Verbose) { Write-Host $msg } }

function Confirm-Action($message) {
  if ($Yes) { return $true }
  if (-not [Environment]::UserInteractive) {
    Write-Error "Use -y/--yes to confirm in non-interactive mode."
    return $false
  }

  $answer = Read-Host "$message [y/N]"
  return $answer -eq "y" -or $answer -eq "Y"
}

# Download to temp directory first
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())

if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
  Log "Downloading ${Repo}@${Version} via curl..."
  New-Item -ItemType Directory -Path "$tmp/scaffold" -Force | Out-Null
  $tarball = "$tmp/repo.tar.gz"
  if ($Version -eq "HEAD") {
    $url = "https://github.com/$Repo/archive/HEAD.tar.gz"
  } else {
    $url = "https://github.com/$Repo/archive/$Version.tar.gz"
  }
  curl.exe -fsL $url -o $tarball
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to download ${Repo}@${Version}. Check that the tag or branch exists."
    exit 1
  }
  tar xzf $tarball --strip-components=1 -C "$tmp/scaffold"
  Remove-Item $tarball
} elseif (Get-Command git -ErrorAction SilentlyContinue) {
  Log "Downloading ${Repo}@${Version} via git..."
  if ($Version -eq "HEAD") {
    git clone --depth 1 "https://github.com/$Repo.git" "$tmp/scaffold" 2>$null
  } else {
    git clone --depth 1 --branch $Version "https://github.com/$Repo.git" "$tmp/scaffold" 2>$null
  }
  Remove-Item -Recurse -Force "$tmp/scaffold/.git"
} else {
  Write-Error "curl or git required"
  exit 1
}

# Remove excluded files from scaffold
Push-Location "$tmp/scaffold"
foreach ($pattern in $Exclude) {
  Get-ChildItem -Filter $pattern -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
}
Pop-Location

# Stage the managed AGENTS.md update; apply it after all confirmations.
$pendingAgents = "$tmp/AGENTS.md.pending"
$hasPendingAgents = $false
$agentsRequireConfirmation = $false

$scaffoldAgents = "$tmp/scaffold/AGENTS.md"
if (Test-Path $scaffoldAgents) {
  $content = Get-Content $scaffoldAgents -Raw
  $startMarker = "<!-- a-team-lite:start -->"
  $endMarker = "<!-- a-team-lite:end -->"
  $managedPattern = "(?ms)^" + [regex]::Escape($startMarker) + "\r?\n.*?^" + [regex]::Escape($endMarker) + "\r?\n?"
  $managedMatch = [regex]::Match($content, $managedPattern)
  if (-not $managedMatch.Success) {
    Write-Error "Scaffold AGENTS.md has no valid A-Team Lite managed block."
    exit 1
  }
  $managedBlock = $managedMatch.Value.TrimEnd("`r", "`n")

  if (Test-Path "AGENTS.md") {
    $existing = Get-Content "AGENTS.md" -Raw
    $startCount = ([regex]::Matches($existing, [regex]::Escape($startMarker))).Count
    $endCount = ([regex]::Matches($existing, [regex]::Escape($endMarker))).Count

    if ($startCount -eq 0 -and $endCount -eq 0) {
      $legacyEnd = 'Only the `designer` agent writes to `DESIGN.md`. Other agents flag gaps back to the designer instead of editing the file directly. Validate edits with `npx @google/design.md lint DESIGN.md`.'
      $legacyPattern = '(?ms)^## Shared Memory\r?\n.*?^' + [regex]::Escape($legacyEnd) + '\r?\n?'
      $legacyRegex = [regex]::new($legacyPattern)
      $baseContent = $existing

      if ($legacyRegex.IsMatch($existing)) {
        Log "Migrating legacy unmarked A-Team instructions in AGENTS.md..."
        $baseContent = $legacyRegex.Replace($existing, "", 1)
        $agentsRequireConfirmation = $true
      } else {
        Log "Appending A-Team Lite workflow to existing AGENTS.md..."
      }

      $separator = if ($baseContent.Length -eq 0) {
        ""
      } elseif ($baseContent.EndsWith("`n")) {
        "`n"
      } else {
        "`n`n"
      }
      [System.IO.File]::WriteAllText($pendingAgents, $baseContent + $separator + $managedBlock + "`n")
      $hasPendingAgents = $true
    } elseif ($startCount -eq 1 -and $endCount -eq 1) {
      $existingPattern = [regex]::new(
        $managedPattern,
        [System.Text.RegularExpressions.RegexOptions]::Multiline -bor
          [System.Text.RegularExpressions.RegexOptions]::Singleline
      )
      $updated = $existingPattern.Replace(
        $existing,
        [System.Text.RegularExpressions.MatchEvaluator]{
          param($match)
          return $managedBlock + "`n"
        },
        1
      )

      if ($updated -eq $existing) {
        Log "A-Team Lite workflow is already up to date."
      } else {
        [System.IO.File]::WriteAllText($pendingAgents, $updated)
        $hasPendingAgents = $true
        $agentsRequireConfirmation = $true
      }
    } else {
      Write-Error "Existing AGENTS.md has duplicate or unmatched A-Team Lite markers."
      Remove-Item -Recurse -Force $tmp
      exit 1
    }
  } else {
    Copy-Item $scaffoldAgents $pendingAgents
    $hasPendingAgents = $true
  }
  Remove-Item $scaffoldAgents
}

# Check for file conflicts and legacy A-Team agents.
$scaffoldFiles = Get-ChildItem -Recurse -File "$tmp/scaffold" | ForEach-Object {
  $_.FullName.Substring("$tmp/scaffold".Length + 1)
}
$conflicts = @()
foreach ($file in $scaffoldFiles) {
  if (Test-Path $file) {
    $conflicts += $file
  }
}

$legacyAgentPaths = @(
  ".github/agents/coder.agent.md",
  ".github/agents/designer.agent.md",
  ".github/agents/marketer.agent.md",
  ".github/agents/orchestrator.agent.md",
  ".github/agents/planner.agent.md",
  ".github/agents/product-manager.agent.md",
  ".github/agents/qa.agent.md",
  ".github/agents/reviewer.agent.md"
)
$legacyAgents = @($legacyAgentPaths | Where-Object { Test-Path $_ })

if ($agentsRequireConfirmation -or $conflicts.Count -gt 0 -or $legacyAgents.Count -gt 0) {
  Write-Host "The following changes require confirmation:"
  if ($agentsRequireConfirmation) {
    Write-Host "  - update managed workflow in AGENTS.md"
  }
  foreach ($f in $conflicts) {
    Write-Host "  - overwrite $f"
  }
  foreach ($f in $legacyAgents) {
    Write-Host "  - remove legacy agent $f"
  }
  if (-not (Confirm-Action "Continue?")) {
    Write-Host "Aborted."
    Remove-Item -Recurse -Force $tmp
    exit 1
  }
}

# Apply all changes after confirmation.
if ($hasPendingAgents) {
  Copy-Item -Force $pendingAgents "AGENTS.md"
}
foreach ($file in $legacyAgents) {
  Remove-Item -Force $file
}
if (Test-Path ".github/agents") {
  $remainingAgents = Get-ChildItem -Force ".github/agents"
  if ($remainingAgents.Count -eq 0) {
    Remove-Item ".github/agents"
  }
}
Copy-Item -Recurse -Force "$tmp/scaffold/*" .
Remove-Item -Recurse -Force $tmp

Write-Host "Done. A-Team Lite installed in current directory."
