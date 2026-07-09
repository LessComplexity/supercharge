# init — bootstrap the docs/ tree from an existing (or empty) codebase

Goal: from a repo with no `docs/` category-architecture tree, produce the full
tree described in `SKILL.md`, grounded in the **real code**, written from
`FRAMEWORK.md`. Run this once; thereafter the tree is *maintained*, not rebuilt.

Read `FRAMEWORK.md` before starting. The order below is deliberate: understand the
system → decompose into components → model each → reconcile upward. Do not write a
roll-up before the things it rolls up exist (deduce, don't invent — §4.3).

---

## Step 0 — Sanity & scope

- Confirm the working directory and that `docs/` (this tree) is genuinely absent.
  If a partial tree exists, switch to `reconcile` for what exists and `init` only
  the gaps.
- Skim the repo: entry points, package/module layout, build files, existing docs
  (`README`, `ADR`s, design notes). These seed the component decomposition — do not
  discard prior art, fold it in.

## Step 1 — Read the system → find the categories (parallel, cheap tier)

The unit of the tree is the **component** (`Cmp`, §4.3): a cohesive bundle of
placements. Decompose the system into components using the code's own seams
(packages, services, bounded contexts, layers), not an invented taxonomy.

Dispatch **read-only agents in parallel**, one per candidate component / top-level
directory. Each returns, for its slice:

- the **`Dat`** it holds — data types/entities and the relations (morphisms) among
  them, with `file:symbol` for each;
- the **`Trn`** it performs — the algorithms, each as `t_from → t_to` with its
  realising `file:symbol` (mark effectful `⊸`);
- any **`Loc`/`Trm`** that is real (a process/thread/node boundary, a wire, disk,
  a network hop). If the whole system runs in one process, `Loc` **collapses** —
  say so; you live in `Dat`+`Alg` (§7.1) and almost every handoff is a `Trn`, not
  a `Trm`.
- its **boundary transmissions** (ports) — how it connects to other components.

Consolidate the returns into a component list. Apply the **Consolidation Principle
(§3) now, before writing anything**: if two candidate components are "the same
objects, different morphisms," they are one — merge them. A folder per *genuine*
component only.

## Step 2 — Write `docs/architecture-map.md` (the whole-system §4 map)

The top-level map. Author it from FRAMEWORK **§4**, **high-level**, per the
template in [`authoring.md`](authoring.md#architecture-mapmd). It must contain:

1. one-paragraph **why** (what modeling this system categorically buys *here*);
2. the **four atoms** at a glance (short tables: key `Dat`, key `Trn`, the `Loc`
   set and whether it collapses, the real `Trm`);
3. a **component table** — one row per component, its owned `Trn`, when it is
   built/active, and a **link to `<component>/ARCHITECTURE.md`**;
4. **placement** reified as spans only where a `Trn`/`Dat` genuinely runs/materialises
   in more than one place (the `runsAt`-is-a-relation cases, §4.2);
5. the **§4.5 coherence checklist** run against the implementation, each law
   PASS/FAIL/`~` with a one-line justification.

Keep it foundational: lay the map and the drill-down pointers; every detail lives
in the component doc it links to. No banter, no narrative padding.

## Step 3 — Populate each component folder (parallelisable)

For every component, create `docs/<component>/` and write, **model-first**:

1. **`ARCHITECTURE.md`** — the component's categorical model (FRAMEWORK §2 olog +
   the §4 atoms it owns). Template: [`authoring.md`](authoring.md#componentarchitecturemd).
2. **`IMPLEMENTATION.md`** — the functor to code: every object & morphism →
   `file:symbol`. Template: [`authoring.md`](authoring.md#componentimplementationmd).
   For a *pre-existing* codebase this is filled from Step 1's map; for a *greenfield*
   component it starts as "planned" rows and is filled during `implement`.
3. **`STATUS.md`** — docs-vs-code reconciliation for this component: what is built /
   partial / unbuilt (checkbox-level), what needs work, and the "where to dig"
   index. Template: [`authoring.md`](authoring.md#componentstatusmd).
4. Create empty `plans/`, `reviews/`, `general/` (a `.gitkeep` or a one-line
   `README` so the dirs persist).

You may fan out one agent per component here (each writes its own four files from
its Step-1 slice), then a review pass for cross-component consistency of shared
objects (the same `Dat` must be named identically across components — it is one
object with multiple `DataLoc`s, not twins).

## Step 4 — Reconcile upward (deduced roll-ups)

Now the per-component files exist, **deduce** the roll-ups (never fork their
content, §4.3):

- **`docs/IMPLEMENTATION.md`** — the whole-system functor: each component → its code
  root + doc links, plus shared objects and inter-component ports/transmissions →
  `file:symbol`. Deduced from the component IMPLEMENTATIONs.
  Template: [`authoring.md`](authoring.md#docsimplementationmd).
- **`docs/STATUS.md`** — one row per component summarising its STATUS (a
  built/partial/unbuilt verdict + headline gaps) and linking to the detail file.
  Kept short and scannable. Template: [`authoring.md`](authoring.md#docsstatusmd).
- Back-fill `architecture-map.md`'s component table and coherence checklist from
  the now-written component ARCHITECTUREs (Step 2 may have used placeholders).

## Step 5 — Generate suggestions

Run `suggest` (see [`status-suggestions.md`](status-suggestions.md)): apply the
category-theory rules to each ARCHITECTURE.md → per-component `suggestions.md` →
roll up `docs/suggestions.md`. This closes `init`.

## Step 6 — Close out

Write a session log `sessions/YYYY-MM-DD-init.md` recording the decomposition
chosen (and any components merged via §3), so the next agent inherits the reasoning
(see [`sessions.md`](sessions.md)). The tree is now live.

---

**Greenfield variant (no code yet).** Same steps, but Step 1 reads the *intent*
(a brief, a spec, the user's description) instead of code. Components come from the
intended decomposition; IMPLEMENTATION.md rows are all "planned"; STATUS is all
unbuilt. The value is that the model exists *before* the code (§6.1) — every later
`plan`/`implement` fills it in.
