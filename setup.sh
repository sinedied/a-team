#!/usr/bin/env bash
set -euo pipefail

REPO="sinedied/a-team"
EXCLUDE="README.md LICENSE setup.sh setup.ps1 assets .gitignore"
# Files retired between scaffold variants. Paths are relative to the install root.
# When upgrading, these are deleted from the target so old agents/skills don't
# coexist with their replacements. Comments on each line document why.
RETIRE_FILES=(
  ".github/agents/designer.agent.md"   # replaced by art-director and game-designer
  ".github/agents/qa.agent.md"         # replaced by playtester
)
RETIRE_DIRS=(
  # add directories here if any skill is retired wholesale
)
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

# Retire files/dirs from a previous scaffold variant if present in the target
retired=()
for f in "${RETIRE_FILES[@]}"; do
  if [ -f "$f" ]; then
    retired+=("$f")
  fi
done
for d in "${RETIRE_DIRS[@]:-}"; do
  if [ -n "$d" ] && [ -d "$d" ]; then
    retired+=("$d/")
  fi
done

if [ ${#retired[@]} -gt 0 ]; then
  echo "The following files/dirs are from a previous scaffold variant and will be removed:"
  for r in "${retired[@]}"; do
    echo "  - $r"
  done
  if ! $YES; then
    if [ -t 0 ]; then
      read -rp "Remove? [y/N] " answer
    elif [ -r /dev/tty ]; then
      read -rp "Remove? [y/N] " answer </dev/tty
    else
      echo "Use -y/--yes to remove retired files in non-interactive mode." >&2
      exit 1
    fi
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
      echo "Aborted."
      exit 1
    fi
  fi
  for r in "${retired[@]}"; do
    rm -rf "$r"
  done
fi

# Handle AGENTS.md separately: append any missing top-level sections section-aware
if [ -f "$tmp/scaffold/AGENTS.md" ]; then
  if [ -f "AGENTS.md" ]; then
    log "Merging AGENTS.md section-aware..."
    # Extract H2 section headings from the new scaffold
    while IFS= read -r heading; do
      [ -z "$heading" ] && continue
      if ! grep -qF "$heading" "AGENTS.md"; then
        # Section missing in target — extract it from the scaffold and append
        section=$(awk -v h="$heading" '
          $0 == h {flag=1; print; next}
          /^## / && flag {flag=0}
          flag {print}
        ' "$tmp/scaffold/AGENTS.md")
        log "  Appending section: $heading"
        printf '\n%s\n' "$section" >> "AGENTS.md"
      fi
    done < <(grep '^## ' "$tmp/scaffold/AGENTS.md")
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
