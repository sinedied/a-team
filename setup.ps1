$ErrorActionPreference = "Stop"

$Repo = "sinedied/a-team"
$Exclude = @("README.md", "LICENSE", "setup.sh", "setup.ps1", "assets", ".gitignore")
$Verbose = $args -contains "--verbose"
$Yes = $args -contains "-y" -or $args -contains "--yes"
$Version = "HEAD"

for ($i = 0; $i -lt $args.Length; $i++) {
  if ($args[$i] -eq "-v" -or $args[$i] -eq "--version") {
    if ($i + 1 -ge $args.Length) {
      Write-Error "--version requires an argument (e.g. v1.0.0)"
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
    $url = "https://github.com/$Repo/archive/refs/tags/$Version.tar.gz"
  }
  curl.exe -fsL $url -o $tarball
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to download ${Repo}@${Version}. Check that the version/tag exists."
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

# Handle AGENTS.md separately: append shared memory rules if missing
$scaffoldAgents = "$tmp/scaffold/AGENTS.md"
if (Test-Path $scaffoldAgents) {
  $content = Get-Content $scaffoldAgents -Raw
  $memoryIdx = $content.IndexOf("## Shared Memory")
  $memorySection = if ($memoryIdx -ge 0) { $content.Substring($memoryIdx) } else { "" }

  if (Test-Path "AGENTS.md") {
    $existing = Get-Content "AGENTS.md" -Raw
    if ($existing -notmatch '(?m)^## Shared Memory') {
      Log "Appending shared memory rules to existing AGENTS.md..."
      Add-Content -Path "AGENTS.md" -Value "`n$memorySection"
    } else {
      Log "AGENTS.md already contains shared memory rules, skipping."
    }
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
