#!/usr/bin/env sh
# Install the category-architect skill for detected agent systems.
#   ./install.sh            -> ~/.claude/skills and/or ~/.codex/skills
#   ./install.sh --project  -> ./.claude/skills and/or ./.codex/skills
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
NAME=$(basename -- "$SRC")
FOUND=0

copy_skill() {
  DEST=$1

  rm -rf "$DEST"
  mkdir -p "$DEST"

  for PATHNAME in "$SRC"/* "$SRC"/.[!.]* "$SRC"/..?*; do
    [ -f "$PATHNAME" ] || [ -d "$PATHNAME" ] || continue
    BASENAME=$(basename -- "$PATHNAME")
    case "$BASENAME" in
      install.sh|.claude|.codex|.git|.gitignore) continue ;;
    esac
    cp -R "$PATHNAME" "$DEST/"
  done
}

install_for() {
  SYSTEM=$1
  DEST_ROOT=$2
  SCOPE=$3
  DEST="$DEST_ROOT/$NAME"

  mkdir -p "$DEST_ROOT"
  copy_skill "$DEST"
  FOUND=1

  echo "Installed '$NAME' for $SYSTEM $SCOPE at:"
  echo "  $DEST"
}

if [ "${1:-}" = "--project" ] || [ "${1:-}" = "-p" ]; then
  BASE=$(pwd)
  SCOPE="in this repo"
else
  BASE=$HOME
  SCOPE="across all projects"
fi

if [ -d "$HOME/.claude" ]; then
  install_for "Claude" "$BASE/.claude/skills" "$SCOPE"
fi

if [ -d "$HOME/.codex" ]; then
  install_for "Codex" "$BASE/.codex/skills" "$SCOPE"
fi

if [ "$FOUND" -eq 0 ]; then
  echo "No Claude or Codex install found at ~/.claude or ~/.codex." >&2
  exit 1
fi

echo "Run once:  /category-architect init"
echo "Then start every session with /category-architect start and end with /category-architect end"
