---
name: scheduled-publication-workflows
description: "Run scheduled publications with explicit delivery checks."
version: 0.1.0
author: Jed, Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [publishing, cron, delivery, verification]
    related_skills: [daily-social-report, daily-social-report-publication, buzz-multipart-delivery, file-newspaper-article]
---

# Scheduled Publication Workflows

Use this for recurring jobs that generate editorial material and publish it to
one or more external destinations. It governs orchestration and completion
state; the content, transport, and repository skills retain their own domain
rules.

## When to Use

- A cron job must generate and publish a report, digest, briefing, or article.
- Completion depends on more than producing a correct final response.
- One publication supplies identifiers or links required by a later one.

Do not use for reminders or jobs whose final response is the complete and
verified deliverable.

## Procedure

1. **Declare the complete skill chain in the scheduled entrypoint.** Preload
   every skill required for generation, transport, filing, and verification,
   or have the entry skill explicitly load each companion before its phase.
   Do not make automatic skill matching a production dependency; a discoverable
   companion skill is not the same as an invoked procedure.

2. **Define the dependency order before running.** Generate the complete
   content first. Publish to the destination that creates downstream IDs or
   URLs next. Verify it, then use only the verified identifiers when filing the
   canonical record or publishing elsewhere.

3. **Choose delivery semantics deliberately.** When multipart delivery or
   read-back verification is required, configure the scheduled final response
   as a local execution record and send external messages explicitly during
   the run. After explicit publication, the final response is a concise status,
   never a duplicate copy of the content.

4. **Delegate transport instead of duplicating it.** Load the destination's
   transport skill, such as `buzz-multipart-delivery`, and follow its preflight,
   fail-fast send, recovery, and read-back rules. The orchestration skill should
   specify when transport occurs, not maintain a second version of how it
   works.

5. **Verify each destination before starting the next dependent phase.** A
   successful tool response proves submission only. Read back messages, remote
   branch files, PR file lists, mergeability, and required checks as applicable.
   Stop rather than constructing downstream records from an unverified event or
   URL.

6. **End with one derived state.** Report `COMPLETE` only when every required
   destination is verified; report `PARTIAL` when at least one destination is
   complete and another is blocked; report `FAILED` when no required
   destination completed. Include the expected and verified counts or concrete
   blocker for each destination.

7. **Make actionable failures visible through an approved path.** The job
   definition or governing skill must name where a partial or failed status is
   sent. If no visible failure destination has been approved, preserve the
   local record and raise that configuration gap to the human owner rather than
   silently inventing a recipient.

## Pitfalls

- Preload the whole workflow - relying on description-based routing can omit a
  companion skill in a fresh cron session.
- Keep one owner for each procedure - duplicated multipart or repository steps
  drift and eventually contradict one another.
- Never file a downstream record with an invented or merely accepted message
  URL - verification establishes the publication identity.
- Treat a scheduler's `ok` status as process completion, not editorial
  completion; only destination read-back establishes success.

## Verification

A scheduled publication workflow is ready only when its entrypoint names the
full skill chain, its delivery mode permits in-run verification, every required
destination has a read-back step, and its final state is mechanically derived
from those verified results.
