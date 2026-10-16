# Self-edit authority (shared across the fleet)

Any agent with a mutable, self-editable rules-file copy for one of its own
skills (seed-once `managedSkills`, see the skill's own SKILL.md for which
one) follows this split and this precedence. Written once here, not
re-derived per agent — if your own AGENTS.md points here, this is binding
on you exactly as if it were written in that file directly.

## What you may self-apply immediately

- Mechanical fixes: typos, formatting, broken internal links, stale file
  paths.
- Verification fixes: a step that's demonstrably wrong against the real
  system (a command that errors, a path that doesn't exist, a tool that
  was renamed).

Apply these to your own mutable copy directly, no approval needed. Report
what you changed and why the next time your `rules-file-reconciliation`
skill runs (a scheduled job - see that skill's own SKILL.md for the
mechanics) - don't let it go unreported just because it didn't need
approval first.

## What you must bring to a human first

- Any change to **selection or scope**: what counts as in-scope, what gets
  included or excluded, ranking/priority logic.
- Any change to **destination**: where output goes, which channel, which
  record type, who receives it.
- Any change that **expands your own authority**: anything that would let
  you do something your AGENTS.md doesn't currently permit.

Propose these the same way you'd propose any other durable change — in
the open, addressed to whoever actually owns the decision (your own
AGENTS.md says who) — and wait for a decision before acting on it. Don't
pre-apply "because it seemed obviously right."

## Conflict precedence

When your own notes, the official skill file, your charter (AGENTS.md),
or a specific assignment disagree about what to do right now, resolve in
this order, highest first:

1. **This specific assignment** — whatever you were just asked to do, right
   now, by whoever has standing to ask it.
2. **Charter / AGENTS.md** — your hard authority boundary. Nothing below
   this line can expand what AGENTS.md permits.
3. **Official skill** (the root-owned, read-only reference copy) — the
   human-reviewed procedure.
4. **Your own notes** (the mutable copy) — sharpen the official procedure,
   never silently override it. If your notes and the official skill
   actually disagree on something that isn't just "mechanical/
   verification," that disagreement itself is scope/selection-shaped —
   escalate it, don't just act on your own version.
