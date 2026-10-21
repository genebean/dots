---
name: buzz-multipart-delivery
description: "Use when publishing long content to Buzz in multiple parts."
version: 1.0.0
author: Jed, Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [buzz, publishing, multipart, verification]
    related_skills: [social-report-delivery, daily-social-report-publication]
required_environment_variables:
  - name: BUZZ_PRIVATE_KEY
    prompt: Buzz identity private key
    help: >-
      Already provisioned per-agent via this fleet's own
      hermes_<agent>_buzz_identity secret - should already be set. Declared
      here so hermes-agent's env-sanitization still passes it through to the
      `buzz` CLI when this skill runs from a cron/background session, not
      just an interactive Buzz-platform one (agents-beads-collaboration-12d).
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
   Label every file and message `Part 1/N`, `Part 2/N`, and so on. Keep each
   part conservatively below the limit rather than targeting the edge.

2. **Preflight Buzz mention parsing.** Remove the literal `@` from external
   social handles in display text while retaining the linked source. Buzz
   treats `@handle` as a channel-member mention and rejects unknown members;
   never add a fake mention to make external attribution pass validation.

3. **Send sequentially and fail fast.** Send one file-backed part with
   `buzz messages send --channel <channel-id> --content - < <part-file>`.
   Confirm the response contains `accepted: true` and save its event ID before
   sending the next part. Do not use an unchecked loop: a rejected early part
   can otherwise leave accepted later parts orphaned in the channel.

4. **Stop on partial failure.** Do not continue the sequence after a rejection.
   Correct the cause, then either send only the clearly missing continuation or
   publish a newly labeled full sequence that explicitly supersedes the partial
   attempt. Never leave two editions whose authoritative parts are ambiguous.

5. **Verify visible state.** Read back enough channel messages to cover every
   expected event ID. Compare each part's label, opening text, final text and
   full item range. Relay ordering can be unstable for messages created in the
   same second, so use part labels and event IDs as the authoritative sequence;
   do not claim chronological ordering that the readback does not show.

6. **Return verified identifiers.** Preserve the first part's event ID and
   message URL for downstream records. Report any superseded or stray part
   plainly rather than presenting the repair as a clean first attempt.

## Pitfalls

- Treat `accepted: true` as submission only; channel readback proves visible,
  complete publication.
- Do not let a scheduled final response duplicate an explicitly sent report;
  after explicit multipart delivery, return only a concise completion note.
- Do not use an external paste or file host as a workaround for Buzz limits.

## Verification

Delivery is complete only when every intended part is visible, every expected
item appears exactly once in the authoritative sequence, the final sentence is
present, and the first-part URL has been retained for downstream publication.
