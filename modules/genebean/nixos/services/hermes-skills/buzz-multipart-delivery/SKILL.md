---
name: buzz-multipart-delivery
description: "Use when publishing long content to Buzz in multiple parts."
version: 1.1.0
author: Jed, Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [buzz, publishing, multipart, verification]
    related_skills: [social-report-delivery, daily-social-report-publication]
---

# Buzz multipart delivery

Publish long Buzz material as a complete, ordered, verifiable sequence. This
skill governs transport and verification, not editorial selection.

## When to Use

- A report or article risks exceeding one Buzz post.
- Complete delivery matters more than fitting everything into one event.
- A failed or truncated post must be replaced with an unambiguous full edition.

Do not use for short messages that clearly fit in one post.

## Procedure

1. **Finish the whole document before sending.** Split it at section
   boundaries or between complete items; never split a paragraph or item.
   Label every file and message `Part 1/N`, `Part 2/N`, and so on. Target
   **at most 60,000 bytes per part** (UTF-8 byte count, not characters -
   emoji and non-ASCII text cost more than one byte each). Buzz's own hard
   limit is 65,536 bytes, enforced identically by the relay and by `buzz`/
   `hermes send` client-side validation (confirmed directly against
   `block/buzz`'s pinned source, `buzz-cli/src/validate.rs`); staying at
   60,000 leaves headroom for markdown/link overhead without needing to
   count bytes exactly. This cap is a clean rejection, not a silent
   truncation - if you ever see content vanish rather than an explicit
   error, the cause is elsewhere, not this limit.

2. **Preflight Buzz mention parsing.** Remove the literal `@` from external
   social handles in display text while retaining the linked source. Buzz
   treats `@handle` as a channel-member mention and rejects unknown members;
   never add a fake mention to make external attribution pass validation.

3. **Send sequentially and fail fast, via `hermes send` - never the bare
   `buzz` binary.** Send one file-backed part with
   `hermes send --to buzz:<channel-id> --file <part-file> --json`. This
   matters beyond style: a scheduled/cron-triggered run has no
   `BUZZ_PRIVATE_KEY` in its terminal-tool environment by design
   (hermes-agent's own GHSA-rhgp-j443-p4rf credential scrub only carves out
   `BUZZ_*` for a session whose platform is literally `buzz` - never cron),
   so a bare `buzz messages send` call fails there even though your identity
   and relay are configured correctly. `hermes send` sidesteps this
   entirely: it reloads `~/.hermes/.env` from disk at its own startup,
   independent of whatever environment the terminal tool handed it, and its
   Buzz path is explicitly built for exactly this case ("one-shot send
   without a live adapter" for out-of-process cron delivery). In an
   interactive/manual Buzz session the bare `buzz` CLI still works fine (the
   carve-out applies there) - `hermes send` works in both contexts, so
   prefer it unconditionally rather than branching behavior by context.
   Parse the `--json` result: `{"success": true, "message_id": "<id>"}` on
   success, `{"error": "..."}` on failure (exit 0 vs 1). Save the
   `message_id` before sending the next part. Do not use an unchecked loop:
   a rejected early part can otherwise leave successfully-sent later parts
   orphaned in the channel.

4. **Stop on partial failure.** Do not continue the sequence after a rejection.
   Correct the cause, then either send only the clearly missing continuation or
   publish a newly labeled full sequence that explicitly supersedes the partial
   attempt. Never leave two editions whose authoritative parts are ambiguous.

5. **Verify visible state.** Read back enough channel messages to cover every
   expected event ID. Compare each part's label, opening text, final text and
   full item range. Relay ordering can be unstable for messages created in the
   same second, so use part labels and event IDs as the authoritative sequence;
   do not claim chronological ordering that the readback does not show.
   **Known gap:** unlike step 3's send, this readback still has no `hermes`-
   native equivalent - `buzz messages get`/`channels search` remain bare
   `buzz` CLI calls, which hit the same cron credential scrub as the old send
   path. In a cron-triggered run, treat each part's `message_id` from step 3
   as the strongest evidence currently available and say so plainly in your
   report, rather than silently skipping verification or claiming a readback
   that didn't actually happen.

6. **Return verified identifiers.** Preserve the first part's event ID and
   message URL for downstream records. Report any superseded or stray part
   plainly rather than presenting the repair as a clean first attempt.

## Pitfalls

- Treat `"success": true` as submission only; channel readback proves
  visible, complete publication.
- Do not let a scheduled final response duplicate an explicitly sent report;
  after explicit multipart delivery, return only a concise completion note.
- Do not use an external paste or file host as a workaround for Buzz limits.

## Verification

Delivery is complete only when every intended part is visible, every expected
item appears exactly once in the authoritative sequence, the final sentence is
present, and the first-part URL has been retained for downstream publication.
