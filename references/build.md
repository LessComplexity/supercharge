# build — plan → implement → test → fix → reconcile

The build flow the skill runs **automatically** whenever it is active and the user
asks to add/change/fix code — no command triggers it. Two phases: **plan**
(model-first design, §6.1) then **implement** (code + tests + fix + reconcile).
Never code a feature before its model exists; never finish without reconciling docs.

---

## plan — design before building

Triggered when new development is requested.

1. **Look for an existing plan.** Search `docs/<component>/plans/plan-*.md` for the
   feature. This is the first rung: a plan may already exist.
   - **If one exists:** read it. Decide whether it still fits the current code and
     the new request. If it needs changes, revise it. **Present the plan (or the
     revision) and ASK the user to proceed or revise** before implementing. Do not
     start coding off a stale or unconfirmed plan.
   - **If none exists:** write one.
2. **Write the plan model-first (§6.1).** A plan is a *design*, so its spine is the
   **categorical model** of the change:
   - which component(s) it touches (or a new component + its folder);
   - the **new/changed objects and morphisms** — signatures, partiality, semantics
     (this is a preview of the ARCHITECTURE.md edit);
   - the **composition rules / invariants** it must preserve;
   - the atoms it adds (`Trn`/`Loc`/`Trm`) and any new placements;
   - a **§3 Consolidation check**: is this genuinely new, or an existing object
     "plus morphisms"? If the latter, the plan is *extend*, not *add* — say so.
   - the **§4.5 laws** the change must keep satisfied.
   - a build→test recipe: the steps, and the tests that will prove it.
3. **Present and confirm.** Show the plan, note the design trade-offs, and ask to
   proceed. Save it to `plans/plan-<slug>.md` regardless (a discarded plan is still
   a decision record).

Plan template:

```markdown
# Plan — <feature/slug>

## Goal
<what this delivers, in one or two lines>

## Component(s) touched
<existing folder(s), or a new component + its planned folder>

## Model delta (preview of the ARCHITECTURE.md edit)
New/changed objects: <...>
| Morphism | Signature | Partiality | Semantics |
| --- | --- | --- | --- |
| `newthing` | `A → B` | Partial | ... |

## Consolidation check (§3)
<new object, or existing object + morphisms? verdict + reason>

## Composition rules / invariants to preserve (§2.5, §4.5)
1. ...

## Build → test recipe
1. <step>  → test: <what proves it>
2. ...

## Risks / trade-offs / open questions
<store-vs-deduce choices, blast radius, anything needing the user's call>
```

---

## implement — code, test, fix, reconcile

Triggered on an approved plan. The loop, in order — **not done until docs are
reconciled with what the code actually became.**

### 1. Code
Implement the plan's model delta. Keep the diff aligned with the ARCHITECTURE.md
intent; where the code must diverge from the plan, note it — you will feed it back
in step 4. Apply §5 principles (isolate effects behind ports, deduce don't store,
one source of truth for shared structure, YAGNI).

### 2. Write tests — at VOLUME, via subagents, covering every edge case
This is the highest-leverage delegation. The suite must be **trustworthy**: a green
run means the behaviour is actually correct, not merely exercised.

Fan out test-writing agents (one per behaviour cluster / component; launch
concurrently). Each agent's brief: enumerate the edge cases the *model* dictates,
then write tests for all of them —

- **Partiality boundaries** — a `Partial` morphism: test where it is defined AND
  where it is undefined (`?`/null/empty). Both branches.
- **Composition-rule invariants** (ARCHITECTURE §6) — one test per invariant
  (`total = subtotal + tax` holds under every mutation path).
- **Deduced morphisms** — assert the deduced value equals its definition and is
  **not** independently stored (guard against the copy that drifts, §5).
- **Coherence-law failure modes** (§4.5) — e.g. a `Trm`'s datum absent at one end
  (Law 1/2), an unmediated cross-`Loc` reach (Law 4).
- **Functor laws** where a functor is claimed — a state machine reaches only legal
  states; a strategy resolver dispatches every registered key.
- **Boundary inputs only** (§5 YAGNI) — validate at the `Trm`s into the component;
  trust internal guarantees, don't test impossible internal states.

No frameworks beyond what the repo already uses; match the existing test style.

### 3. Run tests → fix until green
Run the suite. On failure, fix the **root cause**, not the symptom (grep every
caller of the function you touch; the lazy fix is the shared-function fix). Re-run.
Loop until the whole suite passes. A failing suite is not "done."

Delegate volume fixes if independent, but keep the root-cause discipline: one guard
in the shared morphism beats a guard in every caller.

### 4. Reconcile docs with the built code
Implementing changed the design in ways the plan didn't foresee — **make the docs
true** (§6.3). Run the reconcile steps from [`sessions.md`](sessions.md#end--reconcile):
IMPLEMENTATION.md (new rows, `file:symbol`, `State`) → ARCHITECTURE.md (morphism
table & diagram in step) → component STATUS.md → `docs/IMPLEMENTATION.md` (only if a
code root / shared object / inter-component port changed) → `docs/STATUS.md` → the
map if atoms/components changed. Write a `reviews/review-<slug>.md` running the
change against the §4.5 checklist.

### 5. Session close
If this ends the session, follow [`sessions.md`](sessions.md): write the immutable
log, then confirm all reconciliations are done. Definition of done = code + green
suite + reconciled docs + coherence checklist recorded.

---

## Orchestration summary (tier per §6)

| Step | Delegate | Tier |
| --- | --- | --- |
| Read/locate for the plan | read-only agents, parallel per component | cheap |
| Model delta / design | main thread (or a design agent for hard designs) | high |
| Coding | agent per independent slice | mid |
| Test enumeration + writing | agents in parallel, one per behaviour cluster — **the volume win** | mid, cheap for routine suites |
| Fixing | agent per independent failure cluster, root-cause discipline | mid |
| Reconciliation | agent per component, then one for roll-ups | mid → cheap |
| Coherence-law verification | independent verifiers per law | cheap (power is independence) |

Launch independent agents in one batch so they run concurrently.
