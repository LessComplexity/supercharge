# category-architect → `supercharge` — handoff spec

**Status:** design accepted, not built.
**Audience:** the agent (or person) who will rewrite `category-architect` into a single
Claude Code plugin named `supercharge`.
**Target repo:** *not this one.* This file was authored inside SolidGateway for
convenience; SolidGateway appears below only as the repo where the drift check was
empirically validated. Everything in the spec is repo-agnostic.
**Source skill today:** `~/.claude/skills/category-architect/`
(`SKILL.md` 14.1KB, `FRAMEWORK.md` 49.6KB, `README.md` 10KB,
`references/{authoring,build,init,sessions,status-suggestions}.md`).

Read this top to bottom once. It contains the analysis, the verdict, the target
shape, every file to write, what to delete, the risks, and the build order.

---

## 1. Why this exists

`category-architect` (CA) is a session-continuity + architecture-discipline skill built
on `FRAMEWORK.md` (a categorical model: `Dat` data, `Trn` transformations, `Loc`
locations, `Trm` transmissions, plus §4.5 coherence laws). It owns a fixed `docs/`
tree, a plan→implement→reconcile build flow, and immutable session handoff logs.

Since CA was written, four other tools now cover parts of its surface far better than
prose-in-a-SKILL.md can:

- **semble** — semantic code search over a repo, exposed as MCP (`search`, `find_related`).
- **graphify** — turns a folder into a persistent knowledge graph (`graphify-out/graph.json`,
  community detection, `query` / `path` / `explain`, `--update` incremental, `--mcp`).
- **OpenSpec** — spec-driven work lifecycle with a real CLI and machine-readable state.
- **gbrain** — cross-session, cross-project agent memory over a git-backed brain repo.

CA is now partly redundant and partly irreplaceable. This handoff says exactly which
is which, and packages what survives.

---

## 2. Reference facts on the four tools

Gathered 2026-08-19/20. An implementer should re-verify version-sensitive details.

### 2.1 OpenSpec — `github.com/Fission-AI/OpenSpec`

TypeScript, MIT, default branch `main`. At time of writing: 65,458 stars, 4,509 forks,
214 open issues, last push 2026-08-17. Ships its own `skills/` directory with 12
`SKILL.md` bundles (`openspec-propose`, `openspec-apply-change`, `openspec-archive-change`,
`openspec-continue-change`, `openspec-explore`, `openspec-ff-change`, `openspec-new-change`,
`openspec-onboard`, `openspec-sync-specs`, `openspec-update-change`,
`openspec-verify-change`, `openspec-bulk-archive-change`).

Install: `npm install -g @fission-ai/openspec@latest` (Node ≥ 20.19.0). Also pnpm, yarn,
bun, nix. Then `openspec init` in the project.

Tree it creates:

```
openspec/
├── config.yaml                  # schema choice + `context:` + per-artifact `rules:`
├── specs/<domain>/spec.md       # source of truth: Requirement (SHALL/MUST) + Scenario (GIVEN/WHEN/THEN)
├── changes/<slug>/
│   ├── proposal.md              # intent, scope (in/out), approach
│   ├── design.md                # technical approach + decision records
│   ├── tasks.md                 # numbered checklist, `- [ ] 1.1 …`
│   ├── .openspec.yaml           # optional: schema, created, skip_specs, retire_capabilities
│   └── specs/<domain>/spec.md   # DELTA: `## ADDED|MODIFIED|REMOVED Requirements`
└── changes/archive/YYYY-MM-DD-<slug>/
```

Lifecycle: `/opsx:explore` → `/opsx:propose` → `/opsx:apply` → `/opsx:verify` →
`/opsx:archive`. Archive merges the delta sections into `specs/` and moves the change
folder to `archive/`. Expanded profile adds `/opsx:new`, `/opsx:continue`, `/opsx:ff`,
`/opsx:bulk-archive`, `/opsx:onboard`. Invocation syntax varies per tool
(`/opsx:propose` standard, `/opsx-propose` Cursor/Copilot, `@opsx-propose` Amazon Q,
`$openspec-propose` Codex).

Artifact dependency DAG lives in `schemas/spec-driven/schema.yaml`:

```yaml
name: spec-driven
artifacts:
  - id: proposal
    generates: proposal.md
    requires: []
  - id: specs
    generates: specs/**/*.md
    requires: [proposal]
  - id: design
    generates: design.md
    requires: [proposal]
  - id: tasks
    generates: tasks.md
    requires: [specs, design]
```

Dependencies are **enablers, not gates** — artifacts can be skipped. Schemas are
forkable: `openspec schema fork spec-driven research-first`.

**The reason OpenSpec is worth adopting at all is the machine surface.**
`docs/agent-contract.md` in that repo pins the JSON shapes. The ones that matter here:

| Command | Payload highlights |
|---|---|
| `openspec status --json` | `artifacts[]` with `status: done\|skipped\|ready\|blocked`, in dependency order — **first `ready` entry is what to write next**; `isPlanningComplete`, `applyRequires`, `nextSteps[]` |
| `openspec list --json` | `changes[]` with `completedTasks`, `totalTasks`, `status: no-tasks\|complete\|in-progress` |
| `openspec validate --json` | `items[].valid` + `issues[]` with `level/path/message/line`; **exit 1 when any item fails** |
| `openspec instructions <artifact> --json` | `template`, `instruction`, `context`, `rules`, `dependencies[]`, `unlocks[]` |
| `openspec instructions apply --json` | `tasks[]`, `progress{total,complete,remaining}`, `state: blocked\|all_done\|ready` |
| `openspec archive <name> --json` | `archivedAs: YYYY-MM-DD-name`, `specsUpdated`, `warnings[]` |
| `openspec doctor --json` / `context --json` | health + referenced-store status |

Conventions: exactly one JSON document on stdout in `--json` mode, prose to stderr;
diagnostics share one envelope `{severity, code, message, target?, fix?}`; optional keys
omitted rather than null.

`openspec/config.yaml` carries a free-text `context:` block and per-artifact `rules:`
that get injected into every artifact-generation prompt. **This is the hook that keeps
OpenSpec artifacts categorical** — see §7.3.

Also: `openspec update` regenerates AI guidance and slash commands (so never vendor
those commands); Stores (beta) share specs across repos; telemetry is on by default —
`openspec config set telemetry.enabled false`.

### 2.2 semble

MCP server: `mcp__semble__search`, `mcp__semble__find_related`. CLI fallback
`semble search "<query>" <path> [--content docs|config|all] [--top-k N]`,
`semble find-related <file> <line> <path>`. Index built on first run and cached.
If not on `$PATH`: `uvx --from "semble[mcp]==0.5.5" semble`.

Role: pinpoint retrieval — "where is symbol X", "what else looks like this".

### 2.3 graphify

Local CLI (observed at `~/.local/bin/graphify`) plus a skill at `~/.claude/skills/graphify/`.
Builds `graphify-out/` containing `graph.json`, `graph.html`, `GRAPH_REPORT.md`,
`manifest.json`, `cache/`. Node schema carries `label`, `file_type`, `source_file`,
`source_location`, `_origin` (`ast` / EXTRACTED / INFERRED / AMBIGUOUS), `community`.

Relevant commands: `graphify <path>`, `--update` (incremental, re-extracts changed files
only, tracked via `manifest.json` mtime + ast/semantic hash), `--mode deep`,
`--cluster-only`, `--watch`, `--wiki`, `--mcp`, `--neo4j` / `--falkordb`,
`graphify query "<q>" [--dfs] [--budget N]`, `graphify path "A" "B"`,
`graphify explain "Node"`.

Role: structural orientation — "how does X connect to Y", community view of the corpus,
cross-document links you would not think to ask for.

Datapoint: on the repo this file sits in, `graphify-out/` is 9.1 MB with 2,675 nodes
covering both code and docs.

### 2.4 gbrain — `github.com/garrytan/gbrain`

MIT, by Garry Tan. Persistent memory layer for agents, wired over MCP.

- Storage: a git repo of markdown pages (system of record) synced into PGLite
  (Postgres 17 via WASM + pgvector); ~50K pages before migrating to real Postgres.
- Write: `gbrain capture "…"`, `gbrain capture --file ./notes/today.md`,
  `… | gbrain capture --stdin`. Pages land in `inbox/YYYY-MM-DD-<hash8>`.
  Importers for Gmail/calendar/contacts, Google Takeout, **agent session transcripts**,
  Obsidian/Notion vaults, webhooks, mobile capture.
- Read: hybrid vector + BM25 + reciprocal-rank fusion + reranker, modes
  `conservative | balanced | tokenmax`. `gbrain think` adds synthesis with citations
  **and explicit gap analysis** (states what the brain does not know).
- Graph: typed edges (`works_at`, `founded`, `invested_in`, `attended`, `advises`,
  `mentions`) extracted from wikilinks with zero LLM calls.
- MCP: `gbrain serve --surface verbs` → 7 verbs `recall`, `remember`, `entity`,
  `synthesize`, `forget`, `context_pack`, `delta`. Full surface is 100+ tools.
- Claude Code install: `/plugin marketplace add garrytan/gbrain` then
  `/plugin install gbrain@gbrain`.
- Explicitly **not** a full-text code-search replacement. Target is everything that is
  *not* code — decisions, people, threads, prior sessions.

**Verdict for `supercharge`: out of scope for v1.** See §9.4.

---

## 3. The five slots

The single most useful frame. Every tool answers a different question; the failure mode
is letting two of them answer the same one.

| Slot | Tool | Answers | Scope | State it keeps | Machine-checkable |
|---|---|---|---|---|---|
| Retrieval — pinpoint | **semble** | where is symbol X | current code | index (disposable) | n/a |
| Retrieval — structural | **graphify** | how does X connect to Y | repo corpus graph | `graphify-out/` (rebuildable) | n/a |
| Memory — cross-project | **gbrain** | what did we learn / decide, anywhere | all projects, non-code sources | brain git repo + PGLite | partial |
| Work state | **OpenSpec** | what is in flight, what is next, is it done | one repo, per change | `openspec/` | **yes** (`status`/`validate --json`) |
| Intent | **category-architect** | what the system is *supposed* to be | one repo, durable | `docs/` | no (prose only) |

---

## 4. Verdict — is CA redundant or a superpower?

**Not redundant. It is the only normative tool in the set.**

semble, graphify and gbrain all *describe what exists*. A description derived from the
code can never contradict the code. Drift is only detectable when something independent
asserts intent. CA's `ARCHITECTURE.md` morphism tables, composition rules and §4.5
coherence laws are that independent assertion. Remove CA and you have four excellent
ways to read a codebase and zero ways to know it is wrong.

**But CA's implementation is roughly 40% redundant.** Breakdown:

| CA piece | Now covered by | Action |
|---|---|---|
| `init` mode fan-out (parallel agents reading the system) | graphify (already builds the map, with communities) | **delete** — orient with `graphify query`, fall back to fan-out only when no graph exists |
| `<c>/IMPLEMENTATION.md` hand-typed `file:symbol` rows | semble / graphify derive locations | **keep the rows as normative claims, stop hand-authoring them**; verify mechanically (§8.1) |
| `plans/plan-<slug>.md` + the plan gate | OpenSpec `changes/<slug>/{proposal,design,tasks}.md` | **delete** the template, delegate to `/opsx:propose` |
| `reviews/review-<slug>.md` | `/opsx:verify` (weakly) | **keep**, but only the §4.5 coherence-law checklist — drop the prose review |
| `sessions/*.md` — decision-record half | gbrain `remember` / `think` | overlap; pick one owner (§9.4) |
| `sessions/*.md` — live state + resume commands | nothing | **CA only, keep verbatim** |
| `docs/STATUS.md` per-component built/partial/unbuilt | `openspec list --json` covers per-*change* only | keep, but derive the in-flight column from OpenSpec |
| `suggestions.md` (CT-derived improvements) | nothing | keep, lowest priority — it rots fastest |
| `architecture-map.md` + `<c>/ARCHITECTURE.md` + §4.5 laws | nothing | **the superpower — keep untouched** |
| `FRAMEWORK.md` | nothing | **keep, it is the spine** |

---

## 5. Recommended stack

### 5.1 Read path — add nothing

graphify for structure, semble for pinpoint. A third retrieval tool is waste.

### 5.2 Write path — exactly one owner per artifact

```
intent       → docs/<component>/ARCHITECTURE.md    CA — hand-authored, normative, small
mapping      → docs/<component>/IMPLEMENTATION.md  CA rows, machine-verified by drift-check
in-flight    → openspec/changes/<slug>/            OpenSpec — machine-checkable
behaviour    → openspec/specs/<domain>/spec.md     OpenSpec — observable contract only
continuity   → docs/sessions/<date>-<slug>.md      CA — live state + resume commands
structure    → graphify-out/                       graphify — derived, never hand-edited
```

**Law to write into the skill:** an artifact has exactly one writer. Nothing in
`openspec/changes/` survives past archive. `graphify-out/` is never hand-edited. `docs/`
is never generated wholesale.

### 5.3 The `specs/` vs `ARCHITECTURE.md` boundary

Both can answer "what does this component do". Real duplication risk. Two resolutions —
**pick one per repo and record the choice in the plugin's config**:

- **A — `skip_specs: true`** in each change's `.openspec.yaml`. `ARCHITECTURE.md` is the
  only contract; OpenSpec runs proposal/design/tasks only. Simplest, no duplication,
  loses the scenario→test win.
- **B — scope specs to the external surface.** `openspec/specs/` = observable,
  consumer-facing behaviour (endpoints, status transitions, webhook contracts, CLI
  flags). `ARCHITECTURE.md` = internal objects/morphisms/laws. Recommended when the
  project has real external consumers, because `#### Scenario:` blocks then double as
  the enumerated test list that CA's build flow currently asks an agent to invent.

OpenSpec's own guidance supports the split: specs must avoid internal class/function
names, library choices, and step-by-step implementation — exactly what CA's
`IMPLEMENTATION.md` is for.

---

## 6. The right shape

Two ways to "combine four tools into one plugin". Only one survives contact.

**Wrong shape — vendoring.** Copy graphify's `SKILL.md`, OpenSpec's 12 skills, and CA
into one bundle. Results: duplicate skill descriptions competing for the same triggers,
and every upstream release (`openspec update` regenerates its own slash commands)
breaks the fork.

**Right shape — thin router + glue.** `supercharge` owns the loop and the code that does
not exist anywhere else. The four tools stay upstream, installed independently, updatable.

```
supercharge/
├── .claude-plugin/
│   └── plugin.json            # name, description, version, author
├── .mcp.json                  # semble MCP server (gbrain slot present, commented out)
├── README.md                  # capability exposure — see §10
├── install.sh                 # installs every dependency — see §9
├── FRAMEWORK.md               # vendored from CA — the only large vendored doc, it is ours
├── skills/
│   └── supercharge/
│       ├── SKILL.md           # the router: start | work | end. Nothing else.
│       └── references/
│           ├── docs-tree.md   # the docs/ contract, trimmed from CA authoring.md
│           ├── reconcile.md   # CA build step 4, kept intact
│           ├── sessions.md    # handoff log format, kept intact
│           └── openspec.md    # delegation map: which opsx command, which JSON field
├── commands/
│   ├── supercharge-start.md   # thin alias → Skill(supercharge) args=start
│   ├── supercharge-work.md
│   └── supercharge-end.md
└── scripts/
    ├── preflight.sh           # which of the 4 are present; print the one install line missing
    └── drift-check.sh         # IMPLEMENTATION.md rows → resolve file:symbol → dead rows
```

**Vendored:** `FRAMEWORK.md`, the `docs/` tree contract, the reconcile + sessions
procedures. All originally ours.

**Never vendored:** graphify's skill, OpenSpec's skills or slash commands, semble's
server. Delegate by invoking them; if one is missing, `preflight.sh` says so.

Sizing target: router `SKILL.md` under ~200 lines, references ~400 lines total, scripts
~120 lines. `FRAMEWORK.md` unchanged at ~50 KB.

---

## 7. The three modes

The router `SKILL.md` exposes exactly three. Everything else is delegation.

### 7.1 `start` — restore context

1. `bash scripts/preflight.sh` — report anything missing, continue degraded.
2. If `graphify-out/graph.json` exists → `graphify query "<the user's opening question>"`.
   If not, and the repo has no `docs/` tree, offer to build both (`graphify <path>` then
   the docs scaffold).
3. Read the newest 1–3 `docs/sessions/*.md` (newest first) for live state and resume
   commands.
4. `openspec list --json` → in-flight changes with `completedTasks/totalTasks`.
   For the chosen change, `openspec status --json` → the first `ready` artifact is the
   next thing to write.
5. Read `docs/STATUS.md`, then only the component docs for whatever the user picks.
6. Output: where we were, what is in flight, what resumes it — with the exact commands
   from the session log.

### 7.2 `work` — plan → implement → reconcile

Runs automatically whenever the skill is active and the user asks to add/change/fix code.

1. **Plan** → `/opsx:propose "<description>"`. Do not write `plans/plan-<slug>.md`.
   The categorical discipline is enforced through `openspec/config.yaml` `rules:` (§7.3),
   not through a CA template.
2. **Implement** → `/opsx:apply`. Locate touch sites with semble
   (`mcp__semble__search`), never a blind grep sweep.
3. **Test** — keep CA's volume discipline: partiality boundaries (defined *and*
   undefined branches), composition-rule invariants, deduced-morphism checks (assert the
   value equals its definition and is not separately stored), §4.5 failure modes,
   functor laws, boundary inputs only. When resolution B (§5.3) is in force, every
   `#### Scenario:` in the change's delta spec is already one test.
4. **Reconcile** — CA step 4, unchanged and non-optional:
   `IMPLEMENTATION.md` rows → `ARCHITECTURE.md` morphism table + diagram →
   component `STATUS.md` → root `IMPLEMENTATION.md` (only if a code root, shared object,
   or inter-component port changed) → root `STATUS.md` → `architecture-map.md` (only if
   atoms or components changed). Write `reviews/review-<slug>.md` as the §4.5 checklist run.
5. `bash scripts/drift-check.sh` must pass before archiving.
6. `/opsx:archive` — deltas merge into `openspec/specs/`, change folder moves to archive.

### 7.3 Keeping OpenSpec artifacts categorical

This is the load-bearing integration detail. Write into `openspec/config.yaml` at
`init` time:

```yaml
context: |
  Architecture method: FRAMEWORK.md (Dat / Trn / Loc / Trm + §4.5 coherence laws).
  Every claim must name its object, morphism, location or transmission and map to a
  real file:symbol, a planned item, or an explicit open question. Never invent
  architecture that cannot be grounded.

rules:
  design:
    - State the model delta as objects and morphisms with signature, partiality, semantics
    - Run the §3 Consolidation check — is this a new object, or an existing object plus morphisms?
    - Name the §4.5 coherence laws the change must keep satisfied
    - Isolate effects behind ports; deduce rather than store; one source of truth for shared structure
  specs:
    - Observable, consumer-facing behaviour only — no internal class or function names
    - Every requirement carries at least one happy-path and one failure Scenario
  tasks:
    - Every new or changed morphism gets a row in docs/<component>/IMPLEMENTATION.md with its file:symbol
    - Reconcile ARCHITECTURE.md, IMPLEMENTATION.md and STATUS.md before archiving
    - Run scripts/drift-check.sh and fix dead rows before archiving
```

Rules are injected into every artifact-generation prompt — stronger enforcement than the
same sentences sitting in a `SKILL.md` the model may or may not re-read.

### 7.4 `end` — make the next `start` reliable

1. `bash scripts/drift-check.sh` — dead rows are drift; fix or record them.
2. Reconcile any docs the session touched (§7.2 step 4).
3. `openspec list --json` + `openspec status --json` — paste the in-flight snapshot into
   the session log.
4. Write `docs/sessions/YYYY-MM-DD-<slug>.md`, immutable: decisions made / kept /
   discarded, benchmarks and comparisons, tests run, open ends, **live execution state**
   (running commands, jobs, machines, ports, generated artifacts) and **exact
   resume/inspect commands**. This half has no equivalent in any other tool — it is why
   CA survives.
5. `graphify <path> --update` so the graph tracks the new code.

---

## 8. Scripts to write

### 8.1 `scripts/drift-check.sh` — the highest-value new code

CA's central claim is that `IMPLEMENTATION.md` maps model → code. Nothing verified it.
This does: extract every backticked `path:symbol` from `docs/*/IMPLEMENTATION.md`,
resolve the path against `git ls-files` by path-suffix (so docs may use
repo-relative or service-relative paths), then confirm the symbol still appears in the
file. A dead row is drift.

**Validated:** run against SolidGateway (129 docs, 6 components) it reported
**59 dead / 345 refs — 32 dead paths, 27 dead symbols**, concentrated in one component
(48) whose source directory had been renamed without the docs following. Real signal on
the first run, from ~30 lines.

```bash
#!/usr/bin/env bash
# drift-check — every `path:symbol` claimed in docs/*/IMPLEMENTATION.md must resolve.
# The model says where code should live; this proves it still does. A dead row is drift.
set -uo pipefail
cd "${1:-.}" || exit 2
idx=$(git ls-files); dead=0; total=0
while IFS= read -r doc; do
  while IFS= read -r ref; do
    path="${ref%%:*}"; rest="${ref#*:}"; sym="${rest##*:}"   # handles path:Sym and path:Sym::method
    case "$path" in */*) ;; *) continue ;; esac
    total=$((total+1)); esc=${path//./\\.}
    hits=$(printf '%s\n' "$idx" | grep -E "(^|/)${esc}$")     # suffix match: doc paths may be service-relative
    if [ -z "$hits" ]; then echo "DEAD-PATH   $doc -> $path"; dead=$((dead+1)); continue; fi
    { [ -z "$sym" ] || [ "$sym" = "$path" ]; } && continue
    found=0
    while IFS= read -r h; do grep -qF -- "$sym" "$h" 2>/dev/null && { found=1; break; }; done <<< "$hits"
    [ "$found" -eq 0 ] && { echo "DEAD-SYMBOL $doc -> $path:$sym"; dead=$((dead+1)); }
  done < <(grep -o '`[^`]*`' "$doc" | tr -d '`' \
           | grep -E '^[A-Za-z0-9_./-]+\.[A-Za-z0-9]+::?[A-Za-z0-9_:]+$')
done < <(find docs -name IMPLEMENTATION.md)
echo "--- $dead dead / $total refs"
[ "$dead" -eq 0 ]
```

Notes for the implementer:
- Exits non-zero when anything is dead → drop it straight into CI.
- Grep-for-substring is deliberately loose; a symbol renamed but still a substring of
  something else passes. Upgrade path when it matters: resolve via
  `semble search "<symbol>" <repo>` or the LSP, not a stricter regex.
- Migrations, SQL table names and test-function names all resolve fine with the current
  pattern; prose inside the same table cell is ignored because only backticked spans are
  scanned.
- Optional flag worth adding: `--json` emitting `{dead, total, rows[]}` so the router can
  report without re-parsing text.

### 8.2 `scripts/preflight.sh`

Detect what is installed; print one install line per missing tool; never fail the session.

```bash
#!/usr/bin/env bash
# preflight — report which supercharge dependencies are present.
missing=0
have() { command -v "$1" >/dev/null 2>&1; }
have graphify  || { echo "graphify  MISSING → see install.sh (graphify step)"; missing=1; }
have openspec  || { echo "openspec  MISSING → npm install -g @fission-ai/openspec@latest"; missing=1; }
have semble || have uvx || { echo "semble    MISSING → uv tool install 'semble[mcp]==0.5.5'"; missing=1; }
have git       || { echo "git       MISSING → required by drift-check"; missing=1; }
[ -f openspec/config.yaml ] || echo "note: no openspec/ here → run: openspec init"
[ -d docs ]                 || echo "note: no docs/ tree here → run supercharge init"
[ -f graphify-out/graph.json ] || echo "note: no graph here → run: graphify ."
[ "$missing" -eq 0 ] && echo "preflight OK"
exit 0   # informational only — never block a session
```

---

## 9. `install.sh` — installs every dependency

Requirements the user set: **`install.sh` installs all dependencies.** It must be
idempotent, print what it did, and never silently upgrade something the user pinned.

```bash
#!/usr/bin/env bash
# supercharge install — plugin + all four upstream tools.
set -euo pipefail

SEMBLE_VERSION="${SEMBLE_VERSION:-0.5.5}"
WITH_GBRAIN="${WITH_GBRAIN:-0}"          # opt-in, off by default (see §9.4)

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

say "1/5 Node ≥ 20.19 (required by OpenSpec)"
if have node; then node -v; else
  echo "Node not found. Install Node 20.19+ (nvm/asdf/brew), then re-run."; exit 1
fi

say "2/5 OpenSpec CLI"
if have openspec; then openspec --version
else npm install -g @fission-ai/openspec@latest; fi
openspec config set telemetry.enabled false || true   # opt out by default; user can re-enable

say "3/5 semble (code search MCP)"
if have semble; then semble --version || true
elif have uv;  then uv tool install "semble[mcp]==${SEMBLE_VERSION}"
else echo "no uv — semble will run via 'uvx --from \"semble[mcp]==${SEMBLE_VERSION}\" semble'"; fi

say "4/5 graphify (knowledge graph)"
if have graphify; then graphify --help >/dev/null 2>&1 && echo "graphify present"
else
  echo "graphify not on PATH."
  echo "Install it from its source (pipx/uv tool install, or the project's own installer),"
  echo "then confirm 'graphify --help' works. supercharge degrades gracefully without it."
fi

say "5/5 optional: gbrain (cross-project memory)"
if [ "$WITH_GBRAIN" = "1" ]; then
  echo "Install inside Claude Code:"
  echo "  /plugin marketplace add garrytan/gbrain"
  echo "  /plugin install gbrain@gbrain"
  echo "Then: gbrain serve --surface verbs"
else
  echo "skipped (WITH_GBRAIN=1 to see instructions)"
fi

say "done"
bash "$(dirname "$0")/scripts/preflight.sh" || true
cat <<'NEXT'

Next, per repo:
  openspec init                 # creates openspec/, then paste the rules block from
                                #   references/openspec.md into openspec/config.yaml
  graphify .                    # builds graphify-out/
  /supercharge start            # first command of every session
NEXT
```

Design constraints for whoever writes the real thing:

1. **Never `sudo`.** If a global npm install would need root, say so and stop.
2. **Pin what you can.** semble is pinned; OpenSpec deliberately floats `@latest` because
   `openspec update` expects it — record that choice in the README.
3. **Degrade, do not abort.** Only Node/npm absence is fatal. Everything else prints an
   instruction and continues; `preflight.sh` re-reports at session start.
4. **graphify has no public one-liner** in the material gathered — the installer must
   ask rather than guess a package name. Verify the real install command before shipping.
5. **Telemetry opt-out is a default, not a policy.** Leave the re-enable line in a comment.

### 9.4 gbrain — deliberately optional

Keep the `.mcp.json` slot commented and `WITH_GBRAIN=0`. Reasoning:

- gbrain's win is memory spanning *repos, email, calls, people*. Repo-local continuity is
  already covered by `docs/sessions/` — which is in git, reviewable in PRs, and diffable.
- Two narrative stores means two places to look; the second always goes stale.
- If it is adopted later, **do not fork the writing**: CA stays the author and gbrain
  becomes the cross-project index over it —
  `gbrain capture --file docs/sessions/<newest>.md` at the end of `end`. Its `think`
  gap-analysis is the one capability CA genuinely lacks.

---

## 10. `README.md` — expose the capabilities

The README is the capability surface. Required sections, in order:

1. **One-paragraph pitch.** Five slots, one loop, one install. State plainly that
   `supercharge` does not replace semble / graphify / OpenSpec — it routes them and adds
   the intent layer none of them have.
2. **Install.** `./install.sh`, then per-repo `openspec init` + `graphify .`.
   Node ≥ 20.19 prerequisite. What is optional and what degrades.
3. **The five slots table** — copied from §3. This is the fastest way for a reader to
   understand why four tools are not three too many.
4. **The three modes** — `start`, `work`, `end`, each with what it reads, what it writes,
   and which upstream command it delegates to.
5. **Ownership law** — the §5.2 table. One writer per artifact, verbatim.
6. **What it creates in your repo** — the `docs/` tree, `openspec/`, `graphify-out/`,
   and which of those are hand-authored versus derived.
7. **The formal basis** — short. `FRAMEWORK.md` models the system as `Dat`/`Trn`/`Loc`/`Trm`;
   every claim must be grounded in an object, morphism, location or transmission and map
   to `file:symbol`, a planned item, or an explicit open question. The point is to stop
   agents inventing architecture, not to produce prettier documents. Link to
   `FRAMEWORK.md` rather than restating it.
8. **`drift-check`** — what it proves, the exit code, how to wire it into CI, and the
   measured result from a real repo (59/345) as evidence it finds things.
9. **Degradation matrix** — which modes still work with each tool absent:

   | Missing | `start` | `work` | `end` |
   |---|---|---|---|
   | graphify | orient from `docs/` + sessions only | unaffected | skip `--update` |
   | OpenSpec | no in-flight list | falls back to CA's plan template | no change snapshot |
   | semble | slower location lookups | grep fallback | drift-check unaffected (uses git+grep) |
   | gbrain | unaffected | unaffected | unaffected |

10. **Risks** — §11, honestly stated, including the trigger-collision one.
11. **Migrating from `category-architect`** — §12.

---

## 11. Risks and mitigations

1. **Trigger roulette.** `/supercharge`, `/graphify`, `/opsx:propose` and any surviving
   `/category-architect` all sit in the same skill list. Overlapping descriptions make
   routing *worse*, not better — this is the classic failure of adding a router on top of
   working tools.
   *Mitigation:* `supercharge`'s description covers **only** the session loop and
   architecture discipline. It must never claim "questions about the codebase" (that is
   graphify's trigger) or "propose a change" (OpenSpec's). And retire
   `category-architect` in the same change — five skills where there were four is a
   regression.

2. **Version drift in delegation.** If OpenSpec renames `/opsx:ff`, or graphify changes
   a flag, the router breaks.
   *Mitigation:* every delegated command name lives in exactly one file,
   `references/openspec.md`, never scattered through `SKILL.md`. Pin nothing you do not
   own; `preflight.sh` surfaces version mismatch early.

3. **Four memory stores.** `docs/` + `openspec/` + `graphify-out/` + optionally a gbrain
   repo. Left unpoliced they duplicate within a month.
   *Mitigation:* the §5.2 ownership law goes into `SKILL.md` as a hard rule, plus:
   nothing in `openspec/changes/` survives archive; `graphify-out/` is derived and
   git-ignored; `docs/` is never generated wholesale.

4. **`specs/` vs `ARCHITECTURE.md` duplication.** Both plausibly answer "what does this do".
   *Mitigation:* §5.3 — decide A or B per repo, record it in `openspec/config.yaml`.

5. **Scaffolding before the loop is proven.** Building the plugin first means packaging a
   workflow nobody has run.
   *Mitigation:* the build order in §13. Drift check first, one real change second,
   packaging last.

6. **Upstream churn.** OpenSpec had 214 open issues and a push two days before this was
   written; it moves fast. graphify is local and unversioned in the material gathered.
   *Mitigation:* thin router, no vendoring, `preflight.sh` reporting versions.

7. **Loose symbol matching in drift-check.** Substring grep passes a renamed symbol that
   is still a substring elsewhere.
   *Mitigation:* documented ceiling, upgrade path is semble/LSP resolution. Do not
   pre-build that.

8. **Telemetry.** OpenSpec collects command names and version by default.
   *Mitigation:* `install.sh` opts out; README states it.

---

## 12. Migration map — CA today → supercharge

| CA file | Fate |
|---|---|
| `SKILL.md` (14.1 KB, 4 modes + build flow + orchestration) | **rewrite** as the 3-mode router, ~200 lines. Keep: the grounding rule, the non-negotiables, the ownership law. Drop: `init` fan-out detail, the plan template, the mode-routing table for modes that no longer exist. |
| `FRAMEWORK.md` (49.6 KB) | **vendor unchanged.** The spine. |
| `README.md` (10 KB) | **rewrite** per §10. Much of the existing formal-basis prose is reusable verbatim. |
| `references/init.md` | **mostly delete.** Replace with: run graphify, derive components from its communities, scaffold the docs tree. |
| `references/build.md` | **rewrite as §7.2.** Delete the plan template and step 1 entirely (→ `/opsx:propose`). Keep steps 2–4 — the test-volume discipline and the reconcile order are the valuable parts. |
| `references/sessions.md` | **keep nearly intact** → `references/sessions.md`. Add the `openspec list/status --json` snapshot step. |
| `references/authoring.md` | **split.** Doc templates → `references/docs-tree.md`. Reconcile procedure → `references/reconcile.md`. |
| `references/status-suggestions.md` | **keep, trimmed.** Lowest-value surface; do not expand it. |
| existing `docs/*/plans/*.md` in adopting repos | **leave in place.** Do not migrate history into `openspec/changes/`. New work only. |

---

## 13. Build order

Do not start at step 4.

1. **`drift-check.sh`** — drop it in the target repo's `scripts/`, run it. If it finds
   nothing across the whole `docs/` tree, the premise is wrong and you learned that for
   30 lines. (On the repo this file was written in: 59/345 on the first run.)
2. **One real change through OpenSpec** — `openspec init`, paste the §7.3 rules block,
   run `/opsx:propose` → `/opsx:apply` → reconcile → `/opsx:archive`. Judge whether
   `status --json` actually reduces the "where were we" cost.
3. **Trim CA in place** — rewrite `references/build.md` and `references/init.md` against
   §12, still as `category-architect`. Verify the loop over 2–3 sessions.
4. **Package what survived** as `supercharge`: `plugin.json`, `.mcp.json`, `install.sh`,
   README, router `SKILL.md`, scripts. Retire `category-architect` in the same change.

### Acceptance criteria

- [ ] `./install.sh` on a clean machine ends with `preflight OK` or an explicit,
      actionable list of what is missing.
- [ ] `preflight.sh` never exits non-zero.
- [ ] `drift-check.sh` exits non-zero on a repo with a known-stale `IMPLEMENTATION.md`
      row, and zero after it is fixed.
- [ ] `/supercharge start` in a repo with no `docs/`, no `openspec/` and no graph
      produces a useful answer and offers to scaffold — it does not error.
- [ ] `/supercharge work` on a trivial change produces an OpenSpec change folder,
      reconciled docs, and a passing drift check.
- [ ] `/supercharge end` writes a session log containing live state and at least one
      literal resume command.
- [ ] Exactly one skill in the list claims the session loop; `category-architect` is gone.
- [ ] Removing graphify from `$PATH` degrades all three modes without breaking any.

---

## 14. Open questions for the user

1. **§5.3 — resolution A or B?** Skip OpenSpec specs entirely, or scope them to the
   external surface? B is recommended when the target repo has real external consumers.
2. **graphify's canonical install command** — not established in the material gathered;
   `install.sh` currently asks rather than guesses. Confirm it before shipping.
3. **gbrain in or out of v1?** Recommendation: out, with the `.mcp.json` slot left
   commented. Revisit when memory needs to span repos.
4. **Marketplace or local plugin?** A private marketplace repo makes `/plugin install`
   work for a team; a local path is enough for one machine.
5. **CI wiring** — should `drift-check.sh` gate merges from day one, or run advisory for
   the first month? Advisory is safer given the 17% dead-row baseline measured.
