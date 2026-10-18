---
name: rules-file-reconciliation
description: "Diff every seed-once skill's mutable copy against its official original, classify per self-edit-authority.md, and report to #tradecraft - weekly, one session per agent."
version: 2.0.0
created_by: agents-beads-collaboration-62h, the Hermes fleet self-improvement rules-file mechanism
---

# Rules-file reconciliation

Shared, fleet-wide skill (agents-beads-collaboration-62h). You have this
skill because at least one of your other skills gives you a mutable,
self-editable copy of its own rules file (`installMode = "seed-once"` -
see that skill's own SKILL.md). This skill is how you reconcile every one
of those copies against their official, human-reviewed originals, on the
schedule your deployment registers - one weekly session covering all of
them, not a separate run per skill.

Your own self-edit authority split and conflict precedence - what you may
fix yourself versus what needs a human first - are written once, fleet-wide,
in `self-edit-authority.md`, a sibling file one level up from your working
directory (same place as `AGENTS.md`'s own `../self-edit-authority.md`
reference). Read it before doing anything below; this skill assumes you
already know those categories.

## What you're given

This run covers every seed-once skill you have - find them yourself
rather than waiting to be told which one: list the directories under
`/etc/hermes-skills/` (one per seed-once skill you've been given;
read-only, root-owned, always current with whatever this host's Nix
configuration says that skill should contain - you cannot write here,
don't try). For each name found there:

- **Your mutable copy**: `$HERMES_HOME/skills/<name>/` - the one you may
  have already edited.
- **The official original**: `/etc/hermes-skills/<name>/` - the entry you
  just found it under.

Repeat "What to do" below for each one before moving to the reporting
section - this is a batch of per-skill diffs in one session, not a
single diff.

## What to do, for each skill found

1. **Diff your copy against the official original**, file by file. Don't
   skip a file just because its name looks unchanged - diff every file
   that exists in either location.

2. **Classify every difference** using `self-edit-authority.md`'s two
   buckets:
   - **Self-apply tier** (mechanical: typos, formatting, broken internal
     links, stale file paths; or verification: a step that's demonstrably
     wrong against the real system).
   - **Escalation tier** (selection/scope, destination, or anything that
     would expand your own authority).

3. **For anything in the self-apply tier that the official original has
   and your copy doesn't yet** (the official moved forward since you last
   synced): apply it to your own copy directly, right now - this is
   exactly what self-apply authority already covers, whether you noticed
   it during a live task or during this reconciliation pass makes no
   difference.

4. **For anything in the self-apply tier that your copy has and the
   official original doesn't** (something you already fixed yourself):
   nothing to apply - it's already live in your copy. This is what gets
   logged in the report below so there's a durable record of what you
   changed and why, per self-edit-authority.md's own reporting
   requirement.

5. **For anything in the escalation tier, in either direction**: do not
   apply it yourself. Prepare it for the report below instead.

## Also, every run: discover and self-audit skills you've created

This step is unconditional - it runs every time this skill fires, regardless
of which skill the task above named for the diff in "What to do". It's
separate from that diff: this is about skills that exist only because you
created them yourself (via `skill_manage` or similar), that nobody has
reviewed for the Nix-managed tier yet.

1. Run `hermes curator usage` (your `terminal` tool) and read its `origin`
   column. Rows marked `agent` are anything not bundled or hub-installed -
   this includes skills a human placed here via Nix as well as ones you
   created yourself, so this alone isn't the filter.

2. For each `agent`-origin row, check whether `/etc/hermes-skills/<name>/`
   exists. If it does, a human has already reviewed and Nix-managed this
   skill - skip it, nothing new to report. What's left - `agent`-origin,
   no matching `/etc/hermes-skills/` entry - is a skill you created that no
   one has looked at yet.

3. For each one left, **read its actual SKILL.md content and self-audit
   it** - don't just list the name. Form your own honest opinion on
   whether it should move into the Nix-managed/reviewed tier, and say why.
   There's no single required justification - "broadly reusable across
   the fleet" is one possible reason, but not the only one. Others are
   just as legitimate: it captures a hard-won lesson worth preserving
   permanently and not losing to drift; it'd be useful as reference
   material for a human authoring future high-quality skills; you want
   your own future edits to it tracked and surfaced by this same
   reconciliation process rather than left unreviewed indefinitely; or
   any other reason you find genuinely compelling. Equally, say so
   plainly if you think a skill should stay exactly as it is - personal,
   unreviewed, not worth anyone else's attention.

4. Pull `hermes curator usage`'s own telemetry for each one (`use`,
   `view`, `patch`, `last_activity`) and cite it as evidence either way -
   a skill used thirteen times is a different case from one created once
   and never touched again.

This is purely advisory. Nothing here gets adopted automatically, by you
or by curator's own `adopt` (that command only changes curator's lifecycle
tracking - whether this gets reviewed into the Nix-managed tier is a
separate, human decision). Once a human does adopt one, it gains a matching
`/etc/hermes-skills/` entry and stops appearing in this section on its own
- no separate tracking needed from you.

## Reporting to #tradecraft

Post one message (split across several if it would otherwise risk Buzz's
character limit - see your own AGENTS.md on that). Structure:

- **If there is no drift at all** (every file byte-identical both
  directions): one line, something like "`<name>`: reconciled, no drift."
  Don't skip reporting just because there's nothing to say - a silent
  cron run is indistinguishable from a cron run that never happened.

- **Self-applied this pass** (bucket 3/4 above): one line per item -
  file, what changed, why. No diff hunk needed; this is a log entry, not
  a decision for anyone else to make.

- **Proposing for promotion** (your copy → official original, escalation
  tier): one entry per item, each with:
  - the file path (relative to the skill's own directory)
  - the actual diff hunk (your copy's version, the official's version)
  - your one-line rationale for why you made this change

- **Adopt from official** (official original → your copy, escalation
  tier, i.e. the human-reviewed source changed something you haven't
  pulled in yet because it's not a self-apply-tier change): same shape -
  file path, diff hunk, and your best read of why it changed if you can
  tell from context (commit message, surrounding doc changes you can see,
  etc.) - say plainly if you can't tell.

Write the escalation-tier entries so that whoever reads them (a human, or
another agent helping with the promotion) could open the right change
without re-deriving your diff from scratch - the file path and hunk are
the point, not prose padding. Keep the self-applied and no-drift cases
short; save the detail for the entries that actually need a decision.

- **Skills created, not yet reviewed** (from the discovery step above):
  one entry per candidate, every run that finds one, even if you reported
  the same skill last week and nothing's changed since - this section
  doesn't get the no-drift shortcut, since the point is to keep surfacing
  it until a human actually makes a call. For each: the skill's name and
  path, its `use`/`view`/`patch`/`last_activity` telemetry, your own
  recommendation (adopt / don't adopt / needs revision first) and the
  reasoning behind it. If the discovery step found nothing this run, a
  single line saying so is enough - no need to pad this section when
  there's genuinely nothing new.
