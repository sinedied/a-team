#!/usr/bin/env bash
set -euo pipefail

REPO="sinedied/a-team"
EXCLUDE="README.md LICENSE setup.sh setup.ps1 assets"
VERBOSE=false

for arg in "$@"; do
  case "$arg" in
    -v|--verbose) VERBOSE=true ;;
  esac
done

log() { $VERBOSE && echo "$@" || true; }

# Download to temp directory first
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/scaffold"

if command -v curl &>/dev/null; then
  log "Downloading $REPO via curl..."
  curl -sL "https://github.com/$REPO/archive/HEAD.tar.gz" \
    | tar xz --strip-components=1 -C "$tmp/scaffold"
elif command -v git &>/dev/null; then
  log "Downloading $REPO via git..."
  git clone --depth 1 "https://github.com/$REPO.git" "$tmp/scaffold" 2>/dev/null
  rm -rf "$tmp/scaffold/.git"
else
  echo "Error: curl or git required" >&2
  exit 1
fi

# Remove excluded files from scaffold
cd "$tmp/scaffold"
for pattern in $EXCLUDE; do
  rm -rf $pattern
done
cd - >/dev/null

# Handle AGENTS.md separately: append shared memory rules if missing
if [ -f "$tmp/scaffold/AGENTS.md" ]; then
  memory_section=$(sed -n '/^## Shared Memory/,$p' "$tmp/scaffold/AGENTS.md")
  if [ -f "AGENTS.md" ]; then
    if ! grep -q '^## Shared Memory' "AGENTS.md"; then
      log "Appending shared memory rules to existing AGENTS.md..."
      printf '\n%s\n' "$memory_section" >> "AGENTS.md"
    else
      log "AGENTS.md already contains shared memory rules, skipping."
    fi
  else
    cp "$tmp/scaffold/AGENTS.md" "AGENTS.md"
  fi
  rm "$tmp/scaffold/AGENTS.md"
fi

# Check for conflicts
conflicts=()
while IFS= read -r file; do
  if [ -f "$file" ]; then
    conflicts+=("$file")
  fi
done < <(cd "$tmp/scaffold" && find . -type f | sed 's|^\./||')

if [ ${#conflicts[@]} -gt 0 ]; then
  echo "The following files already exist:"
  for f in "${conflicts[@]}"; do
    echo "  - $f"
  done
  read -rp "Overwrite? [y/N] " answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# Copy files
cp -a "$tmp/scaffold/." .
echo "Done. Agent squad installed in current directory."
