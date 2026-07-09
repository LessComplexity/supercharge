# sessions — start protocol, session logs, and end-of-session reconciliation

Two moments bracket every piece of work: **start** (orient from the docs) and
**end** (reconcile the docs + write an immutable log). Both are defined here.

---

## start — orient a fresh session

Do this before touching code, whenever a session begins or the user says `start`.

1. **Read `FRAMEWORK.md`** (once) — the method for everything below.
2. **Read `docs/sessions/`, latest first.** The most recent 1–3 logs carry the live
   state, open ends, and the agreed next step. Read the latest fully; skim back
   until you have the thread.
3. **Read `docs/STATUS.md`** — the whole-system roll-up: which components are built /
   partial / unbuilt and where the gaps are.
4. **Select by the user's query.** From (2) and (3), pick the **relevant/latest
   session(s)** and the **relevant component `STATUS.md`(s)**. Do not read every
   component doc — route to the ones the query touches.
5. **Drill in.** For the selected component(s), read `STATUS.md` → `ARCHITECTURE.md`
   → `IMPLEMENTATION.md`, and any open `plans/plan-*.md`. Now you know the core of
   the session as if you had run it.
6. **Act.** Answer, or route to `plan` / `implement` (see [`build.md`](build.md)).

If the tree does not exist yet, switch to `init` ([`init.md`](init.md)).

---

## The session log — `sessions/YYYY-MM-DD-<slug>.md`

**Immutable.** Never edit a past log; new findings ⟹ a new log + reconcile the
*living* docs. The bar: another agent reads only this file and continues as though
it ran the session — decisions, numbers, and open ends all present.

Write it at session end (or when the user says `end` / `reconcile`), **before**
reconciling the other docs, so the log captures what actually happened.

Reconcile **all** of the session's findings into it: what was done, what was
concluded, decisions **made / kept / discarded** (with the reason for each),
benchmarks, comparisons, tests run and what they proved, and every open end.

Template:

```markdown
# YYYY-MM-DD — <slug>

## §0 TL;DR
<where it ended, honestly; the single agreed next step.>

## §1 What was done
<the concrete work: features/components touched, code written, files changed.>

## §2 Decisions
| Decision | Verdict | Why |
| --- | --- | --- |
| <option A vs B> | kept A | <reason> |
| <option C> | discarded | <reason> |
Every non-trivial fork recorded — kept AND discarded, each with its reason, so the
next agent doesn't re-litigate.

## §3 Tests & benchmarks
| Test / benchmark | Result | What it proved |
| --- | --- | --- |
| ... | ... | ... |
Record exact configs/numbers, not "passed" — enough to reproduce.

## §4 Architecture / model changes
<structural changes to any ARCHITECTURE.md: new objects/morphisms, changed
placements, coherence-law impact. Flag anything that DIVERGES from the model and why.>

## §5 Open ends
<ordered, each with the doc reference and a build→test recipe, so the next session
continues without further instruction.>

## §6 Docs reconciled this session
<which STATUS / ARCHITECTURE / IMPLEMENTATION / map files were updated.>

## §7 Files changed
<the code files touched.>
```

Adapt the section set to the project — a docs-only session has no §3, a pure
research session no §7 — but keep §0, §2, and §5 always: they are what the next
agent reads first.

---

## end / reconcile — make the living docs true again

After the log is written, reconcile every doc the session affected, **bottom-up**
so each level is deduced from a settled level below it (§4.3):

1. **IMPLEMENTATION.md** (per touched component) — implementing changes the design;
   feed reality back. Add/adjust rows for new morphisms & objects, update each
   `file:symbol` and `State` (`built`/`partial`/`planned`). This is the ground
   truth the rest deduces from.
2. **ARCHITECTURE.md** (per touched component) — if the code changed a documented
   relationship (a new field = a new morphism, §6.3), update the morphism table,
   diagram, and composition rules in step. If code violated a rule, either fix the
   code or add an explicit `Note:` exception (§6.6). Diagram ⇔ table stays exact.
3. **Component `STATUS.md`** — recompute built/partial/unbuilt from the refreshed
   IMPLEMENTATION states; update "needs work" and the "where to dig" index.
4. **`docs/IMPLEMENTATION.md`** — re-deduce the system-level rows: a new/moved
   component code root, a new shared object or inter-component port/transmission.
   Per-morphism detail stays in the component files; only roll up here.
5. **`docs/STATUS.md`** — re-deduce the one-row-per-component roll-up from the
   component STATUS files. Summarise and point; never fork content.
6. **`docs/architecture-map.md`** — only if components/atoms changed: refresh the
   component table, placement rows, and re-run the §4.5 coherence checklist against
   the new code.
7. **suggestions** — if the model changed materially, re-run `suggest` for the
   affected component(s) and refresh `docs/suggestions.md`
   ([`status-suggestions.md`](status-suggestions.md)).

Delegate: one reconciliation agent per touched component (steps 1–3 in parallel),
then a single agent for the roll-ups (steps 4–6). Match tiers per §6.

**Definition of done for a session:** log written + all seven reconcile steps run for
touched areas + the §4.5 checklist green (or a FAIL explicitly recorded as an open
end in §5). The next `start` should open the latest log, read §5, and build.
