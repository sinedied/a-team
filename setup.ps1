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

# Handle AGENTS.md separately: merge the A-Team level-2 (##) sections into any existing
# AGENTS.md — replacing same-heading sections, appending new ones — while preserving the
# user's own heading and non-colliding sections. Copy wholesale for a new project.
$scaffoldAgents = "$tmp/scaffold/AGENTS.md"
if (Test-Path $scaffoldAgents) {
  $scaffold = Get-Content $scaffoldAgents -Raw
  if (Test-Path "AGENTS.md") {
    Log "Merging A-Team sections into existing AGENTS.md..."
    $target = Get-Content "AGENTS.md" -Raw
    $headings = [regex]::Matches($scaffold, '(?m)^## .*$') | ForEach-Object { $_.Value.TrimEnd() }
    # Strip any existing section whose heading matches an A-Team heading.
    foreach ($h in $headings) {
      $he = [regex]::Escape($h)
      $target = [regex]::Replace($target, "(?ms)^$he[^\r\n]*\r?\n.*?(?=^## |\z)", "")
    }
    # Append the A-Team sections (scaffold content from its first ## heading onward).
    $fm = [regex]::Match($scaffold, '(?s)(?:^|\n)(## .*)$')
    $block = if ($fm.Success) { $fm.Groups[1].Value } else { "" }
    $target = $target.TrimEnd() + "`n`n" + $block.TrimEnd() + "`n"
    Set-Content -Path "AGENTS.md" -Value $target -NoNewline
  } else {
    Copy-Item $scaffoldAgents "AGENTS.md"
  }
  Remove-Item $scaffoldAgents
}

# Check for conflicts
$scaffoldFiles = Get-ChildItem -Recurse -File "$tmp/scaffold" | ForEach-Object {
  $_.FullName.Substring("$tmp/scaffold".Length + 1)
}
$conflicts = @()
foreach ($file in $scaffoldFiles) {
  if (Test-Path $file) {
    $conflicts += $file
  }
}

if ($conflicts.Count -gt 0) {
  Write-Host "The following files already exist:"
  foreach ($f in $conflicts) {
    Write-Host "  - $f"
  }
  if (-not $Yes) {
    if ([Environment]::UserInteractive) {
      $answer = Read-Host "Overwrite? [y/N]"
      if ($answer -ne "y" -and $answer -ne "Y") {
        Write-Host "Aborted."
        Remove-Item -Recurse -Force $tmp
        exit 1
      }
    } else {
      Write-Error "Use -y/--yes to overwrite in non-interactive mode."
      Remove-Item -Recurse -Force $tmp
      exit 1
    }
  }
}

# Copy files
Copy-Item -Recurse -Force "$tmp/scaffold/*" .
Remove-Item -Recurse -Force $tmp

Write-Host "Done. Agent squad installed in current directory."
