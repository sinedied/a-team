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

confirm_action() {
  local prompt="$1"

  $YES && return 0
  if [ -t 0 ]; then
    read -rp "$prompt [y/N] " answer
  elif [ -r /dev/tty ]; then
    read -rp "$prompt [y/N] " answer </dev/tty
  else
    echo "Use -y/--yes to confirm in non-interactive mode." >&2
    return 1
  fi
  [[ "$answer" =~ ^[Yy]$ ]]
}

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

# Stage the managed AGENTS.md update; apply it after all confirmations.
agents_pending=false
agents_requires_confirmation=false
pending_agents="$tmp/AGENTS.md.pending"

if [ -f "$tmp/scaffold/AGENTS.md" ]; then
  start_marker='<!-- a-team-lite:start -->'
  end_marker='<!-- a-team-lite:end -->'
  managed_block="$tmp/agents-managed.md"

  awk -v start="$start_marker" -v end="$end_marker" '
    $0 == start { copying = 1 }
    copying { print }
    $0 == end && copying { found_end = 1; exit }
    END { if (!copying || !found_end) exit 1 }
  ' "$tmp/scaffold/AGENTS.md" > "$managed_block" || {
    echo "Error: scaffold AGENTS.md has no valid A-Team Lite managed block." >&2
    exit 1
  }

  if [ -f "AGENTS.md" ]; then
    start_count=$(grep -cFx "$start_marker" "AGENTS.md" || true)
    end_count=$(grep -cFx "$end_marker" "AGENTS.md" || true)

    if [ "$start_count" -eq 0 ] && [ "$end_count" -eq 0 ]; then
      legacy_end='Only the `designer` agent writes to `DESIGN.md`. Other agents flag gaps back to the designer instead of editing the file directly. Validate edits with `npx @google/design.md lint DESIGN.md`.'
      legacy_status="$tmp/legacy-agents-status"
      legacy_clean="$tmp/AGENTS.md.legacy-clean"

      awk -v end="$legacy_end" -v status="$legacy_status" '
        $0 == "## Shared Memory" && !capturing && !removed {
          capturing = 1
          buffered = $0 ORS
          next
        }
        capturing {
          buffered = buffered $0 ORS
          if ($0 == end) {
            capturing = 0
            buffered = ""
            removed = 1
            print "removed" > status
            close(status)
          }
          next
        }
        { print }
        END {
          if (capturing) {
            printf "%s", buffered
          }
        }
      ' "AGENTS.md" > "$legacy_clean"

      if [ -f "$legacy_status" ]; then
        log "Migrating legacy unmarked A-Team instructions in AGENTS.md..."
        agents_requires_confirmation=true
      else
        log "Appending A-Team Lite workflow to existing AGENTS.md..."
      fi

      cp "$legacy_clean" "$pending_agents"
      [ ! -s "$pending_agents" ] || printf '\n' >> "$pending_agents"
      cat "$managed_block" >> "$pending_agents"
      printf '\n' >> "$pending_agents"
      agents_pending=true
    elif [ "$start_count" -eq 1 ] && [ "$end_count" -eq 1 ]; then
      awk -v start="$start_marker" -v end="$end_marker" -v block="$managed_block" '
        BEGIN {
          while ((getline line < block) > 0) {
            managed = managed line ORS
          }
          close(block)
        }
        $0 == start {
          printf "%s", managed
          replacing = 1
          next
        }
        replacing && $0 == end {
          replacing = 0
          next
        }
        !replacing { print }
        END { if (replacing) exit 1 }
      ' "AGENTS.md" > "$pending_agents" || {
        echo "Error: existing AGENTS.md has an invalid A-Team Lite managed block." >&2
        exit 1
      }

      if cmp -s "AGENTS.md" "$pending_agents"; then
        log "A-Team Lite workflow is already up to date."
        rm "$pending_agents"
      else
        agents_pending=true
        agents_requires_confirmation=true
      fi
    else
      echo "Error: existing AGENTS.md has duplicate or unmatched A-Team Lite markers." >&2
      exit 1
    fi
  else
    cp "$tmp/scaffold/AGENTS.md" "$pending_agents"
    agents_pending=true
  fi
  rm "$tmp/scaffold/AGENTS.md"
fi

# Check for file conflicts and legacy A-Team agents.
conflicts_file="$tmp/conflicts"
legacy_agents_file="$tmp/legacy-agents"
: > "$conflicts_file"
: > "$legacy_agents_file"

while IFS= read -r file; do
  if [ -f "$file" ]; then
    printf '%s\n' "$file" >> "$conflicts_file"
  fi
done < <(cd "$tmp/scaffold" && find . -type f | sed 's|^\./||')

legacy_agent_paths=(
  ".github/agents/coder.agent.md"
  ".github/agents/designer.agent.md"
  ".github/agents/marketer.agent.md"
  ".github/agents/orchestrator.agent.md"
  ".github/agents/planner.agent.md"
  ".github/agents/product-manager.agent.md"
  ".github/agents/qa.agent.md"
  ".github/agents/reviewer.agent.md"
)
for file in "${legacy_agent_paths[@]}"; do
  [ ! -f "$file" ] || printf '%s\n' "$file" >> "$legacy_agents_file"
done

conflict_count=$(wc -l < "$conflicts_file" | tr -d ' ')
legacy_agent_count=$(wc -l < "$legacy_agents_file" | tr -d ' ')

if $agents_requires_confirmation || [ "$conflict_count" -gt 0 ] || [ "$legacy_agent_count" -gt 0 ]; then
  echo "The following changes require confirmation:"
  if $agents_requires_confirmation; then
    echo "  - update managed workflow in AGENTS.md"
  fi
  while IFS= read -r f; do
    echo "  - overwrite $f"
  done < "$conflicts_file"
  while IFS= read -r f; do
    echo "  - remove legacy agent $f"
  done < "$legacy_agents_file"
  if ! confirm_action "Continue?"; then
    echo "Aborted."
    exit 1
  fi
fi

# Apply all changes after confirmation.
if $agents_pending; then
  cp "$pending_agents" "AGENTS.md"
fi
while IFS= read -r file; do
  rm -f "$file"
done < "$legacy_agents_file"
if [ -d ".github/agents" ] && [ -z "$(find ".github/agents" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
  rmdir ".github/agents"
fi
cp -a "$tmp/scaffold/." .
echo "Done. A-Team Lite installed in current directory."
