---
name: rules-file-reconciliation
description: "Diff a seed-once skill's mutable copy against its official read-only original, classify every difference per self-edit-authority.md, and report to #tradecraft - weekly, per agent, per skill."
version: 1.0.0
created_by: agents-beads-collaboration-62h, the Hermes fleet self-improvement rules-file mechanism
---

# Rules-file reconciliation

Shared, fleet-wide skill (agents-beads-collaboration-62h). You have this
skill because at least one of your other skills gives you a mutable,
self-editable copy of its own rules file (`installMode = "seed-once"` -
see that skill's own SKILL.md). This skill is how you reconcile that copy
against the official, human-reviewed original, on the schedule your
deployment registers.

Your own self-edit authority split and conflict precedence - what you may
fix yourself versus what needs a human first - are written once, fleet-wide,
in `self-edit-authority.md`, a sibling file one level up from your working
directory (same place as `AGENTS.md`'s own `../self-edit-authority.md`
reference). Read it before doing anything below; this skill assumes you
already know those categories.

## What you're given

The task that invokes this skill names exactly one skill to reconcile, by
name (e.g. "daily-social-report"). For that name:

- **Your mutable copy**: `$HERMES_HOME/skills/<name>/` - the one you may
  have already edited.
- **The official original**: `/etc/hermes-skills/<name>/` - root-owned,
  read-only, always current with whatever this host's Nix configuration
  says that skill should contain. You cannot write here; don't try.

## What to do

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
