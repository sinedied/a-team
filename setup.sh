#!/usr/bin/env bash
set -euo pipefail

REPO="sinedied/a-team"
EXCLUDE="README.md LICENSE setup.sh setup.ps1 assets .gitignore"
VERBOSE=false
YES=false
VERSION="HEAD"

while [ $# -gt 0 ]; do
  case "$1" in
    --verbose) VERBOSE=true; shift ;;
    -y|--yes) YES=true; shift ;;
    -v|--version)
      if [ -z "${2:-}" ]; then
        echo "Error: --version requires an argument (git tag or branch, e.g. v1.0.0 or main)" >&2
        exit 1
      fi
      VERSION="$2"; shift 2 ;;
    *) shift ;;
  esac
done

log() { $VERBOSE && echo "$@" || true; }

# Download to temp directory first
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/scaffold"

if command -v curl &>/dev/null; then
  log "Downloading $REPO@$VERSION via curl..."
  if [ "$VERSION" = "HEAD" ]; then
    url="https://github.com/$REPO/archive/HEAD.tar.gz"
  else
    url="https://github.com/$REPO/archive/$VERSION.tar.gz"
  fi
  if ! curl -fsL "$url" \
    | tar xz --strip-components=1 -C "$tmp/scaffold"; then
    echo "Error: failed to download $REPO@$VERSION. Check that the tag or branch exists." >&2
    exit 1
  fi
elif command -v git &>/dev/null; then
  log "Downloading $REPO@$VERSION via git..."
  if [ "$VERSION" = "HEAD" ]; then
    git clone --depth 1 "https://github.com/$REPO.git" "$tmp/scaffold" 2>/dev/null
  else
    git clone --depth 1 --branch "$VERSION" "https://github.com/$REPO.git" "$tmp/scaffold" 2>/dev/null
  fi
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
  if ! $YES; then
    if [ -t 0 ]; then
      read -rp "Overwrite? [y/N] " answer
    elif [ -r /dev/tty ]; then
      read -rp "Overwrite? [y/N] " answer </dev/tty
    else
      echo "Use -y/--yes to overwrite in non-interactive mode." >&2
      exit 1
    fi
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
      echo "Aborted."
      exit 1
    fi
  fi
fi

# Copy files
cp -a "$tmp/scaffold/." .
echo "Done. Agent squad installed in current directory."
