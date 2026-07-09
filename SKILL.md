---
name: category-architect
description: >
  Model, document, and build ANY software project as a category, using the bundled
  FRAMEWORK.md (Dat/Trn/Loc/Trm + category theory) as the single source of method.
  Establishes and maintains a docs/ knowledge base — a whole-system architecture-map,
  per-component ARCHITECTURE / IMPLEMENTATION / STATUS / suggestions docs, plans,
  reviews, and immutable session logs — and keeps every doc reconciled with the code.
  Use when the user runs /category-architect, or asks to: map or document a project's
  architecture, create an architecture map, categorically model a system or feature,
  start or close out a work session against the docs, plan or implement a feature with
  a design-first flow, reconcile docs with code, or generate improvement suggestions.
---

# Category Architect

A project-agnostic operating system for **designing, documenting, and building**
software as a **category**. The method is defined entirely by the bundled
[`FRAMEWORK.md`](FRAMEWORK.md) — a running system holds/transforms data (`Dat`,
`Trn`) and transmits it between sites (`Loc`, `Trm`); "good architecture" becomes
something you *check* with the §4.5 coherence laws, not argue about.

This skill turns that framework into a repeatable workflow: a **fixed `docs/`
tree**, a set of **document types** each written from the framework, and **modes**
that keep the tree honest across sessions and agents.

> **Read `FRAMEWORK.md` first, once per session, before authoring any doc.** It is
> the base of everything here. Every diagram, table, and review in this skill cites
> a FRAMEWORK section (§n). When code and a doc disagree, the doc states *intent*
> and one of them has a bug (FRAMEWORK §2, §6).

---

## The docs/ tree this skill owns

If it does not exist, **build it** (`init` mode). If it exists, **maintain it**.

```
docs/
├── architecture-map.md      # whole-system §4 map: four atoms, components, coherence
│                            #   checklist. HIGH-LEVEL — foundations + pointers, no banter.
├── IMPLEMENTATION.md        # roll-up functor: architecture-map.md → code roots + shared
│                            #   objects/ports → file:symbol; links to component IMPLEMENTATIONs.
├── STATUS.md                # roll-up of every <component>/STATUS.md, one row per component
├── suggestions.md           # roll-up of every <component>/suggestions.md, CT-driven
├── sessions/
│   └── YYYY-MM-DD-<slug>.md  # immutable per-session logs (never edited after write)
└── <component>/             # one folder per component / feature / part of the system
    ├── ARCHITECTURE.md       # the categorical model of this component (FRAMEWORK §2 + §4)
    ├── IMPLEMENTATION.md     # functor: each object/morphism → real file:symbol
    ├── STATUS.md             # docs-vs-code reconciliation for THIS component
    ├── suggestions.md        # CT-driven improvement proposals for THIS component
    ├── plans/
    │   └── plan-<slug>.md     # a design/plan written BEFORE building
    ├── reviews/
    │   └── review-<slug>.md   # a review written AFTER building (against §4.5 laws)
    └── general/              # notes, investigations, benchmarks, decision records
```

**Naming.** A "component" is whatever the framework calls a `Cmp` (§4.3): a
cohesive bundle of placements — a feature, a service, a subsystem, a package. Use
the codebase's own vocabulary for the folder name (`auth/`, `billing/`, `encoder/`).
Keep it flat: one level of component folders under `docs/`. A component large
enough to have sub-components gets sub-folders *inside* its own folder, each a
smaller copy of the same layout.

---

## Modes — route on the user's request

Some modes are named commands; the rest are **behaviors the skill applies
automatically** whenever it is active. You do not need a command to plan or build —
if the skill is active and the user asks to develop something, follow the build flow.
If unsure which mode, and the choice changes what you touch, ask; otherwise pick the
obvious one and say so.

**Named commands** (an explicit arg, or the obvious situation):

| Mode | Trigger | What it does | Playbook |
| --- | --- | --- | --- |
| **init** | `init`, or the tree is absent | Read the system → write `architecture-map.md` → create a folder + 4 docs per component → reconcile up into `STATUS.md` + `suggestions.md`. | [`references/init.md`](references/init.md) |
| **start** | `start`, or opening a fresh session | Read `sessions/` (latest first) + `docs/STATUS.md`; from the user's query pick the relevant session(s) and component `STATUS.md`(s); drill into that component's docs. Orient, then act. | [`references/sessions.md`](references/sessions.md) |
| **reconcile / end** | `reconcile`, `end`, session close | Write the session log, then reconcile every affected doc bottom-up: IMPLEMENTATION → ARCHITECTURE → component STATUS → `docs/IMPLEMENTATION.md` → `docs/STATUS.md`; refresh `architecture-map.md` if components/atoms changed. | [`references/sessions.md`](references/sessions.md) |
| **suggest** | `suggest` | Apply category-theory rules (§3 Consolidation, §4.5 laws, §5 principles) to each ARCHITECTURE.md → write per-component `suggestions.md` → roll up into `docs/suggestions.md`. | [`references/status-suggestions.md`](references/status-suggestions.md) |

**Automatic behavior — the build flow (no command needed).** Whenever the skill is
active and the user asks to add, change, or fix anything in the code, run this
without being told to, in order (full playbook: [`references/build.md`](references/build.md)):

1. **Plan first (model-first, §6.1).** Look for an existing `plans/plan-<slug>.md`.
   If present, read it, revise if stale, and **present it + ask to proceed or
   revise** before coding. If absent, write one (the categorical model of the
   change) and confirm. Never code a feature before its model exists.
2. **Implement.** Code → write & run tests (edge cases, at volume via subagents) →
   fix until green → **reconcile the docs** with what the code actually became.

A substantive request therefore chains: *(start) → plan → implement → end*. The
plan gate and the closing reconcile are not optional steps the user must invoke —
they are how the skill behaves. Do not skip the reconcile at the end of any work
that changed code.

---

## The document types (all written from FRAMEWORK.md)

Full templates + step-by-step in [`references/authoring.md`](references/authoring.md).
The essence:

- **`architecture-map.md`** — the whole system through FRAMEWORK **§4**. Names the
  four atoms at a glance, lists components in a table (each pointing to its
  `<component>/ARCHITECTURE.md`), reifies placement as spans where it matters, and
  runs the **§4.5 coherence checklist** against the real code. *High-level only:
  lay the foundation and the drill-down pointers; push every detail into the
  component doc it links to. No narrative padding.*

- **`<component>/ARCHITECTURE.md`** — the component through FRAMEWORK **§2** (its
  `Dat` olog: objects, morphism table, functors, composition rules, bridges) plus
  the **§4** atoms it owns (`Trn`/`Loc`/`Trm`, placements). This is the *intended
  specification*, model-first (§6.1). Every diagram arrow appears in a morphism
  table and vice versa.

- **`<component>/IMPLEMENTATION.md`** — the **functor** from the model to the code:
  a table mapping each object and morphism in ARCHITECTURE.md to the concrete
  `file:symbol` that realises it (FRAMEWORK's "realising code" column). This is
  where the model meets the repository; drift here is the earliest signal.

- **`docs/IMPLEMENTATION.md`** — the **whole-system** functor, *deduced* from the
  component IMPLEMENTATIONs: each component → its code root, plus the shared/cross-
  component objects and ports (a `Dat` with `DataLoc`s in two components, an
  inter-component `Trm`) → `file:symbol`. Summarise and link to the component files;
  never fork their rows.

- **`<component>/STATUS.md`** — reconciles the model against the implementation:
  what is built, partial, or unbuilt (checkbox-level, §6.5), what needs work, and
  a "where to dig" index of the component's docs.

- **`docs/STATUS.md`** — one row per component summarising its STATUS, pointing to
  the detailed file. Kept short and scannable.

- **`<component>/suggestions.md`** & **`docs/suggestions.md`** — improvements
  *derived* from category theory (consolidation opportunities, coherence-law
  fixes, deduce-don't-store wins), never taste. Each references the rule it
  applies. See [`references/status-suggestions.md`](references/status-suggestions.md).

- **`sessions/YYYY-MM-DD-<slug>.md`** — an immutable, self-contained log: enough
  that any other agent reads it and continues as if it ran the session. Decisions
  made / kept / discarded, benchmarks, comparisons, tests, open ends.
  See [`references/sessions.md`](references/sessions.md).

---

## Non-negotiable disciplines

1. **Model before code (§6.1).** New feature ⟹ a `plan` with the categorical model
   comes first. No component gets code before it has an ARCHITECTURE.md section.
2. **Reconcile in the same change (§6.3).** A new field is a new morphism: update
   the morphism table and IMPLEMENTATION.md *with* the code, not after. Implementing
   can change the design — feed reality back into the docs at the end of every build.
3. **Deduce, don't redescribe (§4.3, §5).** Roll-up docs (`docs/STATUS.md`,
   `docs/suggestions.md`, `architecture-map.md`'s component views) are *deduced*
   from the per-component files — summarise and point, never fork the content.
4. **The doc is the spec (§6.6).** Code violating a composition rule ⟹ fix the code
   or add an explicit `Note:` exception to the rule. Undocumented exceptions rot.
5. **Immutable sessions.** Never edit a past `sessions/*.md`. New findings ⟹ new log
   + reconcile the *living* docs (STATUS, ARCHITECTURE).
6. **Run the §4.5 checklist before merging** any non-trivial change (FRAMEWORK §8).

---

## Orchestration — use subagents, tier the intelligence (§6)

This workflow is fan-out heavy; delegate, and match the model tier to the step
(FRAMEWORK §6 orchestration table). Concrete assignments:

- **Reading the system for `init`** — dispatch parallel read-only agents, one per
  candidate component / directory, each returning that component's objects,
  morphisms, and `file:symbol` map. Cheap tier (inventory/greps).
- **Test writing at VOLUME** — the biggest win. For each morphism/behaviour, spawn
  agents to enumerate **edge cases** (partiality boundaries, empty/`?` inputs,
  composition-rule invariants, coherence-law failure modes) and write a complete,
  trustworthy suite. One agent per component or per behaviour cluster; run
  concurrently. See [`references/build.md`](references/build.md).
- **Reconciliation** — one agent per component to diff ARCHITECTURE ↔ code and
  refresh IMPLEMENTATION + STATUS; a final agent rolls up `docs/STATUS.md`.
- **Adversarial review** — verify each coherence-law claim with independent
  cheap-tier verifiers (a panel's power is independence, not depth); reserve the
  top tier for framing the model and judging conflicts, never inside the loop.

Always launch independent agents in one batch so they run in parallel.

---

## Quick start for a repo that has never seen this skill

```
/category-architect init
```

→ builds the whole `docs/` tree from the current code, then generates suggestions.
Thereafter open every session with `/category-architect start` and close it with
`/category-architect end`. Full procedures live in `references/`.
