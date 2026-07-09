# sessions - start protocol, handoff logs, and end reconciliation

Two commands bracket every piece of work:

- `start` - recover the shared team/session state before touching code.
- `end` - reconcile docs and write a handoff that makes the next `start` reliable.

The goal is practical continuity: a new agent or teammate should be able to run
`start`, choose an open continuation, and proceed without chat history.

---

## start - recover a fresh session

Do this before touching code whenever a session begins, the user says `start`, or
the user says `continue`.

1. **Read `FRAMEWORK.md` once.** It is the method for every architecture and
   reconciliation decision below.
2. **Read `docs/sessions/`, latest first.** Read the latest log fully. Skim older
   logs only until the open thread is clear.
3. **Extract continuations.** From the latest logs, list open items and any live
   handoff state: running commands, remote/local machines, jobs, ports, generated
   data, branches, files, blockers, and exact inspect/resume commands.
4. **Read `docs/STATUS.md`.** This tells you which components are built, partial,
   or unbuilt, and points to the component docs.
5. **Choose the session to continue.**
   - If the user named a task, pick the matching open item/session.
   - If the user only said `start` or `continue`, show the 1-3 most relevant
     continuations and ask which to resume. If there is exactly one obvious open
     continuation, resume it and say why.
6. **Drill in only where needed.** For selected components, read `STATUS.md` ->
   `ARCHITECTURE.md` -> `IMPLEMENTATION.md`, plus the relevant `plans/` or
   `reviews/` files.
7. **Rehydrate live state.** Run read-only inspect commands from the handoff when
   useful: `git status`, process/job checks, cloud/job status commands, port
   checks, artifact existence checks. Do not restart, stop, or mutate live systems
   unless the user asked or the next step requires it.
8. **Act.** Continue the recorded next step, answer, or route to the build flow
   in [`build.md`](build.md).

If the docs tree does not exist yet, switch to `init` ([`init.md`](init.md)).

---

## The session log - `sessions/YYYY-MM-DD-<slug>.md`

**Immutable.** Never edit a past log. New facts get a new log plus updates to the
living docs (`STATUS`, `ARCHITECTURE`, `IMPLEMENTATION`, map, suggestions).

The bar: another agent can read the latest relevant log and continue as though it
ran the session. Record exact handles and commands, not vibes. Never record secret
values; record secret names only, such as `OPENAI_API_KEY present in shell`.

Write the final log during `end`, after reconciliation, so it can name exactly
which docs were updated. If interrupted before `end` completes, the next `start`
should say the previous session has no final handoff and recover from git/status
facts.

Template:

```markdown
# YYYY-MM-DD - <slug>

## 0. Continuation brief
Current state: <one paragraph, honest and specific>
Next step: <the single best next action>
Resume command/check: `<exact command or file to open first>`

## 1. Work completed
<features/components touched, files changed, docs written, decisions executed.>

## 2. Decisions
| Decision | Verdict | Why |
| --- | --- | --- |
| <option A vs B> | kept A | <reason> |
| <option C> | discarded | <reason> |

Record kept and discarded options so the next session does not re-litigate them.

## 3. Tests, checks, benchmarks
| Check | Result | What it proved |
| --- | --- | --- |
| `<command>` | <exact result> | <meaning> |

Record exact configs/numbers/commit IDs when relevant.

## 4. Live handoff state
| Type | Handle / location | State | Inspect / resume | Stop / cleanup |
| --- | --- | --- | --- | --- |
| branch | `<branch>` | <dirty/clean/ahead> | `git status` | <none/command> |
| process | <pid/session/name> | <running/stopped/unknown> | `<command>` | `<command or none>` |
| machine/job | <provider/id/url> | <running/done/unknown> | `<command or URL>` | `<command or owner>` |
| port | `<host:port>` | <serving/free/unknown> | `<command>` | `<command or none>` |
| artifact | `<path or bucket/key>` | <created/partial/needed> | `<command>` | <keep/delete rule> |
| data | `<dataset/table/file>` | <read/written/queued> | `<command>` | <rollback/none> |

Include only rows that exist. If state cannot be verified, write `unknown` and the
next inspect command. Do not leave live infrastructure or generated data only in
chat.

## 5. Open items
| Priority | Item | Doc/code reference | Next action | Done when |
| --- | --- | --- | --- | --- |
| P0 | <thing> | `<path>` | <exact next step> | <observable check> |

Every open item must have a next action and a done check.

## 6. Architecture / model changes
<new/changed objects, morphisms, placements, coherence-law impact, and any known
model/code divergence.>

## 7. Docs reconciled
| Doc | Change |
| --- | --- |
| `<path>` | <what was reconciled> |

## 8. Files changed
<code/config/doc files touched, or `none`.>
```

Adapt sections only by omission when truly irrelevant. Keep sections 0, 2, 4, 5,
and 7 every time; they are the handoff.

---

## end / reconcile - make the next start reliable

Run this whenever the user says `end`, `reconcile`, or the work session is about
to stop.

1. **Snapshot live state.** Inspect and record:
   - git branch/status and uncommitted work;
   - running local commands, dev servers, ports, terminals, logs;
   - remote machines, cloud jobs, queues, schedulers, deployments;
   - generated artifacts, datasets, exports, uploads, or temporary files;
   - blockers, approvals needed, and owner of the next decision.
2. **Identify open items.** Each item needs priority, reference, next action, and
   done check. If there are no open items, say `none`.
3. **Reconcile affected docs bottom-up** so each level is deduced from settled
   detail below it (§4.3):
   - per-component `IMPLEMENTATION.md` - update objects/morphisms, `file:symbol`,
     and `State` (`built`/`partial`/`planned`);
   - per-component `ARCHITECTURE.md` - update model tables, diagrams, composition
     rules, and explicit `Note:` exceptions;
   - component `STATUS.md` - recompute built/partial/unbuilt and needs-work rows;
   - `docs/IMPLEMENTATION.md` - roll up component roots, shared objects, and
     inter-component ports/transmissions;
   - `docs/STATUS.md` - roll up component state;
   - `docs/architecture-map.md` - refresh only if components/atoms/coherence
     changed;
   - suggestions - refresh if the model changed materially.
4. **Run or record checks.** Run the relevant tests/checks. If a check cannot run,
   record why and the next command.
5. **Write the immutable session log.** Use the template above. It must include
   live handoff state, open items, docs reconciled, and exact resume/inspect
   commands.
6. **Final sanity statement.** State the next `start` path: latest log to read,
   open item to continue, and first command/file to inspect.

Delegate reconciliation one component per agent when useful, then roll up once.
Use independent verifiers for coherence-law claims when the change is non-trivial.

**Definition of done for a session:** docs reconciled, session log written, live
state recorded or explicitly `none`, open items recorded or explicitly `none`, and
the next `start` has a clear first step.
