# category-architect

A Claude Code / Codex **skill** that makes an AI agent design, document, and build
any software project as a **category** — using the bundled `FRAMEWORK.md`
(Dat/Trn/Loc/Trm + category theory) as the single source of method.

It gives a project a self-maintaining `docs/` knowledge base:

- `docs/architecture-map.md` — a high-level whole-system map (four atoms,
  components, coherence checklist) that links down to detail;
- `docs/<component>/` — per component: `ARCHITECTURE.md` (the categorical model),
  `IMPLEMENTATION.md` (model → code map), `STATUS.md`, `suggestions.md`, plus
  `plans/`, `reviews/`, `general/`;
- `docs/IMPLEMENTATION.md`, `docs/STATUS.md`, `docs/suggestions.md` — deduced
  whole-system roll-ups;
- `docs/sessions/` — immutable per-session logs any agent can resume from.

…and the workflow to keep all of it reconciled with the code across sessions and
across many agents.

---

## Install

### From GitHub

```bash
git clone https://github.com/<owner>/category-architect.git
cd category-architect
./install.sh
```

Replace `<owner>` with the GitHub user or org that publishes this repo.
Re-running `./install.sh` updates the installed skill in place.

For a project-only install:

```bash
./install.sh --project
```

### From a downloaded folder

From inside the unpacked `category-architect/` folder:

```bash
./install.sh            # installs into detected ~/.claude/skills and/or ~/.codex/skills
./install.sh --project  # installs into detected ./.claude/skills and/or ./.codex/skills
```

### Copy by hand

```bash
# personal (all projects)
cp -R category-architect ~/.claude/skills/
cp -R category-architect ~/.codex/skills/

# or project-scoped (this repo only)
mkdir -p .claude/skills && cp -R category-architect .claude/skills/
mkdir -p .codex/skills && cp -R category-architect .codex/skills/
```

That's it — no dependencies. Claude Code and Codex auto-discover skills in their
`skills/` directories. Restart the session (or start a new one) and the skill is
live.

---

## Use

```
/category-architect init      # bootstrap the docs/ tree from your existing code
/category-architect start     # orient a new session from the docs
/category-architect end       # write the session log + reconcile all docs
/category-architect suggest   # category-theory-derived improvement backlog
```

Or just describe the task — "map this project's architecture", "plan feature X",
"reconcile the docs with the code" — and the skill routes to the right mode.

`FRAMEWORK.md` is bundled and is the base of everything. The agent reads it first
each session. Every generated doc cites the framework section it applies.

---

## What's in this folder

```
category-architect/
├── SKILL.md                    # the skill: overview, doc tree, modes, disciplines
├── FRAMEWORK.md                # the method (category theory) — base of everything
├── README.md                   # this file
├── install.sh                  # copies the skill into place
└── references/
    ├── init.md                 # bootstrap procedure
    ├── authoring.md            # how to write each doc type, with templates
    ├── sessions.md             # start protocol + session logs + reconciliation
    ├── build.md                # plan → implement → test → fix → reconcile
    └── status-suggestions.md   # STATUS reconciliation + CT-derived suggestions
```

Portable and self-contained — hand the folder (or the zip) to anyone.
