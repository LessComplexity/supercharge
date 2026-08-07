#!/usr/bin/env sh
# Install the category-architect skill for detected agent systems.
#   ./install.sh            -> ~/.claude/skills, ~/.codex/skills, ~/.config/opencode/skills,
#                              $KIMI_CODE_HOME/skills (Kimi Code CLI, default ~/.kimi-code/skills,
#                              else ~/.agents/skills), and/or Kimi Work's skills dir
#   ./install.sh --project  -> ./.claude/skills, ./.codex/skills, ./.opencode/skills,
#                              and/or ./.kimi-code/skills (else ./.agents/skills)
#                              (Kimi Work has no project scope; it still installs at user level)
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
      install.sh|.claude|.codex|.opencode|.kimi|.kimi-code|.agents|.git|.gitignore) continue ;;
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

if [ -d "$HOME/.config/opencode" ]; then
  if [ "$BASE" = "$HOME" ]; then
    install_for "opencode" "$HOME/.config/opencode/skills" "$SCOPE"
  else
    install_for "opencode" "$BASE/.opencode/skills" "$SCOPE"
  fi
fi

# Kimi Code CLI. Per the official docs, it scans user-level skills in
# $KIMI_CODE_HOME/skills (default ~/.kimi-code/skills) or the cross-tool
# ~/.agents/skills, and project-level skills in ./.kimi-code/skills or
# ./.agents/skills. Prefer the Kimi-specific root; fall back to the shared
# agents dir when only that exists.
if [ -n "${KIMI_CODE_HOME:-}" ] || [ -d "$HOME/.kimi-code" ]; then
  KIMI_CODE_HOME=${KIMI_CODE_HOME:-"$HOME/.kimi-code"}
  if [ "$BASE" = "$HOME" ]; then
    install_for "Kimi Code" "$KIMI_CODE_HOME/skills" "$SCOPE"
  else
    install_for "Kimi Code" "$BASE/.kimi-code/skills" "$SCOPE"
  fi
elif [ -d "$HOME/.agents" ]; then
  if [ "$BASE" = "$HOME" ]; then
    install_for "Kimi Code" "$HOME/.agents/skills" "$SCOPE"
  else
    install_for "Kimi Code" "$BASE/.agents/skills" "$SCOPE"
  fi
fi

# Kimi Work (kimi-desktop app). Skills live in one user-level directory, so
# there is no project scope; --project still installs here. Override the root
# with KIMI_WORK_HOME if it lives elsewhere (e.g. on another platform).
KIMI_WORK_HOME=${KIMI_WORK_HOME:-"$HOME/Library/Application Support/kimi-desktop/daimon-share/daimon"}

if [ -d "$KIMI_WORK_HOME" ]; then
  if [ "$BASE" = "$HOME" ]; then
    install_for "Kimi Work" "$KIMI_WORK_HOME/skills" "$SCOPE"
  else
    install_for "Kimi Work" "$KIMI_WORK_HOME/skills" "across all projects (Kimi Work has no project scope)"
  fi
fi

if [ "$FOUND" -eq 0 ]; then
  echo "No Claude, Codex, opencode, Kimi Code, or Kimi Work install found at ~/.claude, ~/.codex, ~/.config/opencode, ~/.kimi-code, ~/.agents, or $KIMI_WORK_HOME." >&2
  exit 1
fi

echo "Run once:  /category-architect init"
echo "Then start every session with /category-architect start and end with /category-architect end"
