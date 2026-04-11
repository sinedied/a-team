$ErrorActionPreference = "Stop"

$Repo = "sinedied/a-team"
$Exclude = @("README.md", "LICENSE", "setup.sh", "setup.ps1", "assets")

# Download to temp directory first
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())

if (Get-Command npx -ErrorAction SilentlyContinue) {
  npx --yes degit $Repo "$tmp/scaffold"
} elseif (Get-Command git -ErrorAction SilentlyContinue) {
  git clone --depth 1 "https://github.com/$Repo.git" "$tmp/scaffold" 2>$null
  Remove-Item -Recurse -Force "$tmp/scaffold/.git"
} else {
  Write-Error "npx or git required"
  exit 1
}

# Remove excluded files from scaffold
Push-Location "$tmp/scaffold"
foreach ($pattern in $Exclude) {
  Get-ChildItem -Filter $pattern -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
}
Pop-Location

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
  $answer = Read-Host "Overwrite? [y/N]"
  if ($answer -ne "y" -and $answer -ne "Y") {
    Write-Host "Aborted."
    Remove-Item -Recurse -Force $tmp
    exit 1
  }
}

# Copy files
Copy-Item -Recurse -Force "$tmp/scaffold/*" .
Remove-Item -Recurse -Force $tmp

Write-Host "Done. Agent squad installed in current directory."
