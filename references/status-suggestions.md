# status & suggestions — the two reconciliation/derivation doc types

Both doc types are **derived**, not freshly authored: STATUS is deduced from the
implementation vs the model; suggestions are deduced from the model by category-
theory rules. Neither invents content — they reconcile or apply rules.

---

## STATUS — model vs code, reconciled

### `<component>/STATUS.md`

Reconciles the component's ARCHITECTURE.md (intent) against its IMPLEMENTATION.md
(reality). Checkbox-level completeness (§6.5). The `State` column in
IMPLEMENTATION.md is the ground truth — STATUS aggregates it and adds judgement
about what still needs work.

```markdown
# <Component> — status

> Reconciles ARCHITECTURE.md (intent) vs IMPLEMENTATION.md (code). Source of truth
> for what's built here. Updated whenever code changes what's done (§6.5).

## Headline
<one line: built / partial / unbuilt, and the single most important gap>

## Completeness
| Object / morphism (from ARCHITECTURE §4) | State | Notes |
| --- | --- | --- |
| `rel` | ✅ built | |
| `port_x` | 🟡 partial | adapter stubbed, no retry |
| `newthing` | ⬜ unbuilt | planned in plans/plan-x.md |

## Needs work
1. <the concrete next thing, with why>

## Coherence
<any §4.5 law currently FAILing or advisory-only for this component>

## Where to dig
- Model: ARCHITECTURE.md
- Code map: IMPLEMENTATION.md
- Open plans: plans/plan-*.md
- Reviews: reviews/review-*.md
- Notes/benchmarks: general/
```

### `docs/STATUS.md`

The whole-system roll-up: **deduced** from the component STATUS files (§4.3), one
row each, short and scannable. Summarise and point — never fork the detail.

```markdown
# System status

> Roll-up of every <component>/STATUS.md. One row per component. Details live in
> the linked file — this stays scannable.

| Component | State | Headline gap | Detail |
| --- | --- | --- | --- |
| Encoder | ✅ built | — | [encoder/STATUS.md](encoder/STATUS.md) |
| Billing | 🟡 partial | refunds unbuilt | [billing/STATUS.md](billing/STATUS.md) |
| Search | ⬜ unbuilt | design only | [search/STATUS.md](search/STATUS.md) |

## Cross-cutting
<system-wide open ends: coherence FAILs, atoms that de-collapse at scale, etc.>
```

Legend: ✅ built · 🟡 partial · ⬜ unbuilt. Keep the roll-up regenerable from the
parts, so `end`/`reconcile` can rebuild it mechanically.

---

## suggestions — improvements DERIVED from category theory

Not taste. Every suggestion cites the FRAMEWORK rule it applies and names the
concrete change. Think step by step over each ARCHITECTURE.md, hunting these
specific, checkable smells:

- **Consolidation (§3).** Two objects that are "the same objects, different
  morphisms" → merge, make the extra morphisms partial + a discriminator. A
  junction table that only marks a subset → a partial field. A translator/adapter
  between shapes differing only in populated fields → delete it. Look for the
  §3 warning signs: parallel entry points, twin models with a bridge, docs that
  must explain "the difference between two almost-same things."
- **Deduce-don't-store (§5).** A stored value computable from others (cache,
  denormalized column, mirrored state) with no consistency mechanism → deduce it,
  or justify the copy + name the consistency mechanism. Copied display data that
  should resolve *through* a morphism (§3 corollary) → deduce through it.
- **Coherence-law fixes (§4.5).** Any law currently FAILing → the fix that restores
  it (a missing `DataLoc`/`Trm` for Law 1/2, mediation for Law 4, a `runsAt` column
  to remove for Law 6).
- **One source of truth (§5).** Two near-identical structures that can drift → push
  the difference to a single declared seam (a provider/parameter/strategy).
- **Ports & strategy (§5, §4.4).** A core transmission landing on a *concrete*
  external component → put a port between them so the partner is glued from outside.
- **Anchor on the durable entity (§3 corollary).** A link routed through a transient
  actor/session instead of the durable entity → re-anchor.
- **YAGNI (§5).** A morphism/abstraction modeled for a hypothetical future, an
  interface with one implementation, validation for states that cannot occur →
  remove until the third call site appears.

### `<component>/suggestions.md`

```markdown
# <Component> — suggestions (category-theory derived)

> Improvements deduced from ARCHITECTURE.md by FRAMEWORK rules. Each cites its rule
> and names the concrete change. Not applied — a backlog for future work.

| # | Rule (§) | Smell found | Proposed change | Payoff |
| --- | --- | --- | --- | --- |
| 1 | §3 Consolidation | `Guest` and `Member` share all objects | merge into `User` + `kind?` discriminator, drop the translator | one vocabulary, no drift |
| 2 | §5 Deduce | `order.tax` stored, no reconcile job | deduce `tax = rate ∘ jurisdiction` | removes a drift source |
| 3 | §4.5 Law 4 | `A` reaches `B` across process, no `Trm` | add the boundary transmission | fixes unmediated cross-Loc reach |

## Detail
### 1. <title>
<the reduction worked through: the naive model, the functor, which squares commute,
the verdict — per §3's five-step procedure — when the suggestion is a consolidation.>
```

### `docs/suggestions.md`

The roll-up: **deduced** from the per-component files, highest-payoff first, one
line each, linking to the detail.

```markdown
# System suggestions (category-theory derived)

> Roll-up of every <component>/suggestions.md, highest payoff first. Detail in the
> linked component file.

| # | Component | Rule (§) | Change | Payoff | Detail |
| --- | --- | --- | --- | --- | --- |
| 1 | Billing | §3 | merge Guest/Member | kills the translator | [billing/suggestions.md](billing/suggestions.md#1) |

## System-wide reductions
<cross-component consolidations: the same Dat modeled as twins in two components,
a shared structure forked across components — the biggest wins live here.>
```

**Applying a suggestion** is a normal `plan` → `implement` cycle
([`build.md`](build.md)): the suggestion becomes a plan, gets confirmed, built,
tested, and reconciled — and its row moves out of suggestions into the changelog of
the session log.
