---
name: hindsight-global-memory
description: When to read/write the hindsight-global MCP connection — durable, cross-repository knowledge (infra conventions, tooling preferences, organization-wide decisions) that lives outside any one repo's automatic per-repo memory. Use when the user says "remember this everywhere" / "note this for future repos", a task touches shared tooling/CI/conventions that span repositories, or something feels like it should already be known but isn't showing up in this repo's own memory.
---

# Hindsight Global Memory

This machine has two independent Hindsight memory surfaces, and they solve different problems:

- **Per-repo memory** (the `hindsight` MCP server / `coding-agent::<repo>` banks) — automatic,
  zero-effort, scoped to one repository. This is what the `hindsight-coding-agent` skill already
  covers: architecture, conventions, decisions, and initiatives *for the repo you're currently in*.
- **`hindsight-global`** (this skill) — a separate MCP connection to one durable bank that is
  **not** tied to any repository. It holds knowledge that should follow you across every repo:
  organization-wide conventions, shared infrastructure, cross-repo dependencies, tooling
  preferences, and lessons learned that generalize beyond where they were first discovered.

Nothing copies automatically between the two. A per-repo session is never silently mirrored into
`hindsight-global`, and `hindsight-global` is never auto-injected into every prompt the way
per-repo memory is — that would just recreate "one giant bank" and drown genuinely relevant results
under irrelevant cross-project noise. Reaching for `hindsight-global` is always a deliberate step,
by you or by the user, not a background process.

## When to write to `hindsight-global`

Retain something there when it is durable AND not specific to the repo you're currently in:

- shared CI/build conventions ("Nix builds across repos use this pattern")
- an organization-wide decision or standard ("don't add X back; it was deliberately removed")
- how repos depend on or need to be coordinated with each other
- infrastructure or tooling preferences that apply regardless of which repo you're in
- a root-cause lesson learned in one repo that's genuinely applicable elsewhere

Do **not** retain repo-specific facts there ("this page's search feature needs workaround Y") —
that belongs in the current repo's own per-repo bank, which already handles it automatically.

When you see something like this mid-session, say so and retain it explicitly — don't wait to be
asked, but don't retain silently either: surface it ("noting for future sessions via
hindsight-global: ...") so the user can correct you if it's not actually durable/general enough.

## When to read from `hindsight-global`

Don't query it on every turn — that defeats the point of keeping per-repo recall focused. Reach for
it when the current task looks like one of these:

- it involves shared tooling, CI, or an organization-wide convention
- it touches infrastructure or config that's likely to span multiple repos
- something about a cross-repo dependency or coordination is unclear
- the user asks "why do we do it this way" and the answer plausibly predates or transcends this repo
- per-repo memory came up empty or thin on something that feels like it should already be known

Use the `hindsight-global` MCP tools directly (`retain`/`recall`/`reflect`) for this — they operate
on the one fixed bank this connection points at, not the per-repo one.

## Crediting

Same rule as per-repo memory: if anything `hindsight-global` returns reaches your reply — quoted,
paraphrased, or merely confirming what you were about to say — open that part with:

> 🧠 **From hindsight-global** — <the specific fact you drew on>

A query that turned up nothing useful needs no mention at all.
