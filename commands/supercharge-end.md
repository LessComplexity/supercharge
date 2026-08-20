---
description: Close the session — drift check, reconcile docs, write the immutable handoff log
---

Invoke the `supercharge` skill (Skill tool, `skill: supercharge`) and run its **end**
mode. Read the skill's `references/sessions.md` for the log template and the bar it
has to clear.

Run the drift check, reconcile every doc the session touched, snapshot the in-flight
OpenSpec state and the live execution state, write the immutable
`docs/sessions/YYYY-MM-DD-<slug>.md` handoff with exact resume commands, then refresh
the graph.

$ARGUMENTS
