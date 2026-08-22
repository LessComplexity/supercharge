#!/usr/bin/env sh
# supercharge install — the plugin/skill plus every upstream tool it delegates to.
#
#   ./install.sh              user-level skill install + dependencies
#   ./install.sh --project    project-level skill install (this repo only) + dependencies
#   ./install.sh --no-deps    skill only, skip the dependency steps
#
# Principles: never sudo; degrade rather than abort; never silently upgrade a pin.
# Re-running is safe — present tools are reported, not reinstalled.
set -u

SEMBLE_VERSION="${SEMBLE_VERSION:-0.5.5}"
SHIM_DIR="${SHIM_DIR:-$HOME/.local/bin}"

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SKILL_SRC="$SRC/skills/supercharge"
NAME=supercharge
FOUND=0
DEPS=1
BASE=$HOME
SCOPE="across all projects"

for arg in "$@"; do
  case "$arg" in
    --project|-p) BASE=$(pwd); SCOPE="in this repo" ;;
    --no-deps)    DEPS=0 ;;
    -h|--help)    sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  esac
done

say()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ------------------------------------------------------------------ dependencies
if [ "$DEPS" -eq 1 ]; then

say "1/5 Node (OpenSpec needs >= 20.19.0)"
if have node; then
  node -v
else
  echo "Node not found. Install Node 20.19+ (nvm / asdf / brew), then re-run to add OpenSpec."
  echo "supercharge still installs and runs without it — the 'work' mode loses its machine-checkable"
  echo "change state and falls back to writing the change folder by hand."
fi

say "2/5 OpenSpec (work state)"
if have openspec; then
  openspec --version
elif have npm; then
  # deliberately @latest, not pinned: 'openspec update' regenerates a project's slash
  # commands from the installed version, so a stale pin drifts against the docs it writes.
  npm install -g @fission-ai/openspec@latest || echo "openspec install failed — install it by hand later"
else
  echo "no npm — install Node, then: npm install -g @fission-ai/openspec@latest"
fi
# Telemetry is ON by default upstream. Opting out is our default, not a policy:
# re-enable any time with  openspec config set telemetry.enabled true
have openspec && openspec config set telemetry.enabled false >/dev/null 2>&1

say "3/5 semble (pinpoint code search)"
if have semble; then semble --version
elif have uv;   then uv tool install "semble[mcp]==${SEMBLE_VERSION}" || echo "semble install failed"
else echo "no uv — semble will run via: uvx --from \"semble[mcp]==${SEMBLE_VERSION}\" semble"; fi

say "4/5 graphify (structural knowledge graph)"
if have graphify; then graphify --version
elif have uv;    then uv tool install graphifyy || echo "graphify install failed — see https://pypi.org/project/graphifyy/"
else echo "no uv — install uv (https://docs.astral.sh/uv/), then: uv tool install graphifyy"; fi

say "5/5 gbrain (cross-project memory)"
if have gbrain; then
  gbrain --version
else
  # gbrain is a Bun + TypeScript runtime. It is NOT on npm — the npm package named
  # "gbrain" is an unrelated GPU/ML library. github:garrytan/gbrain or a git clone are
  # the only supported sources. See INSTALL_FOR_AGENTS.md in that repo.
  if ! have bun; then
    echo "Bun not found (gbrain requires >= 1.3.10). Installing from the official bun.sh script."
    curl -fsSL https://bun.sh/install | bash || echo "bun install failed — see https://bun.sh"
    [ -d "$HOME/.bun/bin" ] && PATH="$HOME/.bun/bin:$PATH" && export PATH
  fi
  if have bun; then
    bun install -g github:garrytan/gbrain || {
      echo "bun install -g failed. Deterministic fallback:"
      echo "  git clone https://github.com/garrytan/gbrain.git ~/gbrain && cd ~/gbrain && bun install && bun link"
    }
  else
    echo "no bun — install it (https://bun.sh), then: bun install -g github:garrytan/gbrain"
    echo "NEVER 'npm install -g gbrain' — that is an unrelated package."
  fi
fi
if have gbrain; then
  echo
  echo "gbrain needs a one-time interactive setup (a brain repo + an embedding API key):"
  echo "  gbrain init            # ~30 min, asks for keys"
  echo "  gbrain doctor          # verifies the install"
  echo "MCP + curated skills in Claude Code:"
  echo "  /plugin marketplace add garrytan/gbrain"
  echo "  /plugin install gbrain@gbrain"
  echo "Ownership stays put: supercharge authors docs/sessions/, gbrain only indexes it"
  echo "at the end of 'end' —  gbrain capture --file docs/sessions/<newest>.md"
fi

fi   # end dependencies

# ------------------------------------------------------------------ the skill
copy_skill() {
  DEST=$1
  rm -rf "$DEST"
  mkdir -p "$DEST"
  cp -R "$SKILL_SRC/." "$DEST/"
}

install_for() {
  SYSTEM=$1; DEST_ROOT=$2
  mkdir -p "$DEST_ROOT"
  copy_skill "$DEST_ROOT/$NAME"
  FOUND=1
  echo "  $SYSTEM -> $DEST_ROOT/$NAME"
}

say "Installing the '$NAME' skill $SCOPE"

[ -d "$SKILL_SRC" ] || { echo "missing $SKILL_SRC — run this from the repo root" >&2; exit 1; }

# Systems that support both user- and project-level skill folders.
[ -d "$HOME/.claude" ]          && install_for "Claude"    "$BASE/.claude/skills"
[ -d "$HOME/.codex"  ]          && install_for "Codex"     "$BASE/.codex/skills"

if [ -d "$HOME/.config/opencode" ]; then
  if [ "$BASE" = "$HOME" ]; then install_for "opencode" "$HOME/.config/opencode/skills"
  else                          install_for "opencode" "$BASE/.opencode/skills"; fi
fi

# Kimi Code CLI: $KIMI_CODE_HOME/skills (default ~/.kimi-code/skills) at user level,
# ./.kimi-code/skills at project level.
if [ -n "${KIMI_CODE_HOME:-}" ] || [ -d "$HOME/.kimi-code" ]; then
  KIMI_CODE_HOME=${KIMI_CODE_HOME:-"$HOME/.kimi-code"}
  if [ "$BASE" = "$HOME" ]; then install_for "Kimi Code" "$KIMI_CODE_HOME/skills"
  else                          install_for "Kimi Code" "$BASE/.kimi-code/skills"; fi
fi

# ~/.agents/skills is the CROSS-TOOL skills dir several agents read, not a Kimi
# fallback — install there whenever it exists, independently of Kimi Code.
if [ -d "$HOME/.agents" ]; then
  if [ "$BASE" = "$HOME" ]; then install_for "shared (.agents)" "$HOME/.agents/skills"
  else                          install_for "shared (.agents)" "$BASE/.agents/skills"; fi
fi

# User-level only — these agents keep skills in one directory with no project scope,
# so --project still installs here. Paths follow each tool's own installer convention.
[ -d "$HOME/.copilot" ]         && install_for "GitHub Copilot CLI" "$HOME/.copilot/skills"
[ -d "$HOME/.pi" ]              && install_for "Pi"        "$HOME/.pi/agent/skills"
[ -d "$HOME/.hermes" ]          && install_for "Hermes"    "$HOME/.hermes/skills"
[ -d "$HOME/.config/devin" ]    && install_for "Devin"     "$HOME/.config/devin/skills"

# Kimi Work (desktop) keeps skills in one user-level dir — no project scope.
KIMI_WORK_HOME=${KIMI_WORK_HOME:-"$HOME/Library/Application Support/kimi-desktop/daimon-share/daimon"}
[ -d "$KIMI_WORK_HOME" ] && install_for "Kimi Work" "$KIMI_WORK_HOME/skills"

if [ "$FOUND" -eq 0 ]; then
  echo "No agent system found at ~/.claude, ~/.codex, ~/.config/opencode, ~/.kimi-code," >&2
  echo "~/.agents, ~/.copilot, ~/.pi, ~/.hermes, ~/.config/devin, or $KIMI_WORK_HOME." >&2
  echo "Cursor, Gemini CLI and the AGENTS.md-convention agents are not covered — they" >&2
  echo "wire skills through a rules file or a markdown section, not a skill folder." >&2
  exit 1
fi

# ------------------------------------------------------------------ AGENTS.md
# Aider, OpenClaw, Factory Droid, Trae and Codex do not load a skill folder — they read
# a markdown section. One writer covers all of them. The block is marker-delimited, so
# re-running replaces it in place and deleting it by hand is a clean uninstall.
AG_BEGIN="<!-- supercharge:begin -->"
AG_END="<!-- supercharge:end -->"

agents_section() {
  printf '%s\n' "$AG_BEGIN"
  cat <<SECTION
## supercharge — session loop and architecture discipline

Full instructions: \`$1/SKILL.md\`. Read it before acting on any of the below.

- **Start every session** by restoring context: run \`supercharge-preflight\`, read the
  newest \`docs/sessions/*.md\` for live state and exact resume commands, then
  \`openspec list --json\` for what is in flight. Do not touch code first.
- **When asked to add, change or fix code**, plan through OpenSpec rather than writing
  a plan doc, locate touch sites with semble, then reconcile
  \`docs/<c>/IMPLEMENTATION.md\` → \`ARCHITECTURE.md\` → \`STATUS.md\` before archiving.
- **End every session** by running \`supercharge-drift\`, reconciling the docs the
  session touched, and writing an immutable \`docs/sessions/YYYY-MM-DD-<slug>.md\`
  containing live execution state and exact resume commands.
- **Never invent architecture.** Every claim names a Dat/Trn/Loc/Trm and maps to a real
  \`file:symbol\`, a planned item, or an explicit open question. Otherwise it is not
  architecture — it is an open question.
SECTION
  printf '%s\n' "$AG_END"
}

write_agents_md() {
  f=$1; skillpath=$2
  mkdir -p "$(dirname "$f")" 2>/dev/null
  [ -f "$f" ] || : > "$f"
  if grep -qF "$AG_BEGIN" "$f" 2>/dev/null; then
    awk -v b="$AG_BEGIN" -v e="$AG_END" '
      $0 == b { skip = 1 } { if (!skip) print } $0 == e { skip = 0 }
    ' "$f" > "$f.sc-tmp" && mv "$f.sc-tmp" "$f"
    verb="updated"
  else
    verb="added"
  fi
  # keep exactly one blank line before the block when the file already has content
  [ -s "$f" ] && printf '\n' >> "$f"
  agents_section "$skillpath" >> "$f"
  echo "  $verb section in $(echo "$f" | sed "s|$HOME|~|")"
}

say "AGENTS.md section (Aider, OpenClaw, Factory Droid, Trae, Codex)"
AG_SKILL="$HOME/.agents/skills/supercharge"
[ -d "$HOME/.agents/skills/supercharge" ] || AG_SKILL="$HOME/.claude/skills/supercharge"

[ -d "$HOME/.codex"  ] && write_agents_md "$HOME/.codex/AGENTS.md"  "$AG_SKILL"
[ -d "$HOME/.agents" ] && write_agents_md "$HOME/.agents/AGENTS.md" "$AG_SKILL"
if [ "$BASE" != "$HOME" ]; then
  write_agents_md "$(pwd)/AGENTS.md" "$AG_SKILL"   # the file project-scoped agents read
fi
echo "  (delete the marked block to remove — nothing else is touched)"

# ------------------------------------------------------------------ script shims
# The scripts are invoked by name from SKILL.md, so they must resolve the same way in
# every agent system — none of which agree on a plugin root. Copied, not symlinked, so
# they keep working if this checkout moves; re-run the installer to update them.
say "Script shims in $SHIM_DIR"
mkdir -p "$SHIM_DIR"
for pair in "drift-check.sh:supercharge-drift" "preflight.sh:supercharge-preflight"; do
  script=${pair%%:*}; shim=${pair##*:}
  cp "$SKILL_SRC/scripts/$script" "$SHIM_DIR/$shim"
  chmod +x "$SHIM_DIR/$shim"
  echo "  $shim"
done
case ":$PATH:" in
  *":$SHIM_DIR:"*) ;;
  *) echo "  note: $SHIM_DIR is not on \$PATH — add it, or call the scripts by full path" ;;
esac

# ------------------------------------------------------------------ report
say "Dependency report"
bash "$SKILL_SRC/scripts/preflight.sh"

cat <<'NEXT'

Next, per repo:
  openspec init            # then paste the context:/rules: block from
                           #   references/openspec.md into openspec/config.yaml
  graphify .               # builds graphify-out/  (add it to .gitignore)
  /supercharge-start       # first command of every session

Or load it as a plugin instead of a bare skill (also wires the semble MCP server):
  Claude Code:  /plugin marketplace add LessComplexity/supercharge
                /plugin install supercharge@supercharge
  Codex:        codex plugin marketplace add LessComplexity/supercharge
                codex plugin add supercharge@supercharge
NEXT
