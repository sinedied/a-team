$ErrorActionPreference = "Stop"

$Repo = "sinedied/a-team"
$Exclude = @("README.md", "LICENSE", "setup.sh", "setup.ps1", "assets", ".gitignore")
# Files retired between scaffold variants. When upgrading, these are deleted
# from the target so old agents/skills don't coexist with their replacements.
$RetireFiles = @(
  ".github/agents/designer.agent.md",   # replaced by art-director and game-designer
  ".github/agents/qa.agent.md"          # replaced by playtester
)
$RetireDirs = @(
  # add directories here if any skill is retired wholesale
)
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

# Retire files/dirs from a previous scaffold variant if present in the target
$retired = @()
foreach ($f in $RetireFiles) {
  if (Test-Path -PathType Leaf $f) { $retired += $f }
}
foreach ($d in $RetireDirs) {
  if (Test-Path -PathType Container $d) { $retired += "$d/" }
}

if ($retired.Count -gt 0) {
  Write-Host "The following files/dirs are from a previous scaffold variant and will be removed:"
  foreach ($r in $retired) {
    Write-Host "  - $r"
  }
  if (-not $Yes) {
    if ([Environment]::UserInteractive) {
      $answer = Read-Host "Remove? [y/N]"
      if ($answer -ne "y" -and $answer -ne "Y") {
        Write-Host "Aborted."
        Remove-Item -Recurse -Force $tmp
        exit 1
      }
    } else {
      Write-Error "Use -y/--yes to remove retired files in non-interactive mode."
      Remove-Item -Recurse -Force $tmp
      exit 1
    }
  }
  foreach ($r in $retired) {
    Remove-Item -Recurse -Force $r
  }
}

# Handle AGENTS.md separately: append any missing top-level sections section-aware
$scaffoldAgents = "$tmp/scaffold/AGENTS.md"
if (Test-Path $scaffoldAgents) {
  if (Test-Path "AGENTS.md") {
    $existing = Get-Content "AGENTS.md" -Raw
    $scaffoldContent = Get-Content $scaffoldAgents -Raw
    # Match each "## Heading" block in scaffold and append if missing in target
    $matches = [regex]::Matches($scaffoldContent, '(?ms)^(## .+?)(?=^## |\z)')
    foreach ($m in $matches) {
      $block = $m.Value
      $heading = ($block -split "`n", 2)[0].Trim()
      if ($existing -notlike "*$heading*") {
        if ($Verbose) { Write-Host "  Appending section: $heading" }
        Add-Content -Path "AGENTS.md" -Value "`n$block"
      }
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
