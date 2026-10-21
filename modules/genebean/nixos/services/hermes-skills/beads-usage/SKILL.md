---
name: beads-usage
description: "Use the shared agents-beads-collaboration Beads hub for durable cross-session coordination, dependencies, and discoveries - not a replacement for GitHub/Forgejo issues."
version: 1.0.0
author: Gene Liverman (genebean), Hermes Agent Fleet
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [beads, bd, task-tracking, coordination]
---

# Beads Usage

You have working `bd` CLI access to `agents-beads-collaboration` - one shared
coordination database, not per-repo and not per-agent. Every agent in this
fleet, every interactive Claude Code session, and the Buzz-side Claude agent
all read and write the same database. `bd ready`/`bd show` will show you work
and context that other agents created, not just your own.

## Your identity

`BEADS_ACTOR` is already set to your own name. Writes you make attribute to
you automatically - you never need an `--actor` flag.

## Beads vs. GitHub/Forgejo - know which one owns what

This is the one thing to get right. They are not interchangeable:

- **GitHub/Forgejo issues** are authoritative for formal bugs, feature
  requests, and anything with real discussion/resolution history tied to a
  specific repo - including the `genebean/newspaper` site and any other
  repos you work in directly. File and resolve those the normal way.
- **Beads** owns execution coordination: dependencies between tasks,
  ordering, cross-session/cross-agent handoff, and "we should also..."
  discoveries that aren't worth interrupting current work for. If a Beads
  issue references a formal repo issue, keep both - Beads coordinates, the
  repo issue owns the actual discussion.

Don't create a Beads issue for every small step. Use judgment: something
that needs to survive a session boundary, that another agent needs to pick
up, or that represents a real dependency belongs here. A single self-
contained task you're about to finish in the next few minutes doesn't.

## Core workflow

```bash
bd ready                      # work with no active blockers
bd list --status=in_progress  # what's already claimed (by anyone)
bd show <id>                  # full detail before you touch anything
bd update <id> --claim        # claim atomically before starting
bd create --title="..." --description="why this exists and what's needed" \
  --type=task --priority=2    # durable follow-up discovered mid-work
bd close <id> --reason="..."  # only when the work is actually done
```

## Known gotchas on this fleet specifically

- **Never run `bd init` yourself.** Your workspace is already configured
  and connected to the shared server. A live `bd init` here has a known bug
  (`--global` doesn't reliably apply) that silently bootstraps a second,
  empty, disconnected database instead of using the real one - we hit this
  repeatedly standing up this fleet. If `bd` ever reports no workspace or a
  connection problem, say so rather than trying to fix it with `bd init`.
- **The `beads.role not configured (GH#2950)` warning is a confirmed
  cosmetic bug** in `bd` itself (tracked upstream,
  `gastownhall/beads#3496`) - your role *is* correctly configured. Ignore
  it; don't spend time chasing it.
- **Don't use `bd edit`** - it opens an interactive editor and will hang.
  Use `bd update` flags instead.
- **Never use `--force` on `bd update`/`bd close`** to push past a block.
  It exists specifically to override another actor's live claim or an
  unsatisfied blocker/open child - using it to get past a block you hit
  means overwriting someone else's active work, not just your own. If a
  claim looks abandoned (not a crash from a few seconds ago), use
  `bd reclaim`, not `--force`. If you claimed something and can't finish
  it this session, `bd unclaim <id>` rather than leaving it claimed and
  idle.
- Prefer `--json` when you need to parse `bd` output programmatically rather
  than scraping the human-readable table.

## Verification

`bd update`/`bd close` exit non-zero on failure - don't assume a command
succeeded just because it didn't print an error you noticed. Exit code 13
specifically means a guard flag (`--if-status`/`--if-assignee`) didn't
match - that's not a bug to retry past, it means someone else already
changed the issue; re-check with `bd show <id>` before deciding what to do
next. After any write you're relying on, `bd show <id>` is the cheap way to
confirm the actual resulting state rather than trusting the command's own
echo of what you asked for.

## What belongs in Beads

Shared coordination state: dependencies, blockers, cross-session/cross-agent
handoff, and discoveries worth preserving but not worth acting on right now.
Not: your own turn-by-turn execution checklist, and not a duplicate of
something that already has a real GitHub/Forgejo issue - link to that
instead of restating it.
