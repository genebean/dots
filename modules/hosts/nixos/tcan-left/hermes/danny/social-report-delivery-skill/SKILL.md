---
name: social-report-delivery
description: "Use when manually rerunning or publishing social reports."
version: 1.1.0
---

# Social Report Delivery

Use this for manual reruns, recovery after a scheduled report fails, and
explicit publication of an already-generated social report. Use the
report-generation skill for editorial ranking; this skill governs the
rerun and delivery boundary.

## Procedure

1. **Reload the report-generation skill first.** Treat its current input
   paths, privacy rules, report shape, and link conventions as
   authoritative; deployment fixes may change them between the failed
   run and the retry.
2. **Read only the generation skill's named content inputs.** Do not
   compensate for a failed scheduled run by fetching live feeds when the
   pipeline supplies a compiled candidate file; live reads can advance
   cursors or double-count material.
3. **Identify the snapshot precisely.** Use the compiled file's
   `generated_at`, `since`, candidate count, platform counts, and any
   error/cap metadata. When the original scheduled snapshot is
   unavailable, label the result as a current repaired snapshot rather
   than claiming to reconstruct the earlier run.
4. **Generate the complete report before publishing.** Apply the private
   recipient profile at runtime without copying its topic lists or rules
   into durable files. Split a long report at section boundaries, never
   in the middle of an item.
5. **Choose delivery by invocation context.** A cron invocation with an
   explicit delivery target publishes through its final response. A
   manual request in another channel does not inherit that target, so
   publish explicitly to the intended report channel rather than leaving
   the report only in the request thread.
6. **Resolve the destination instead of hardcoding it.** For Buzz:
   `buzz --format compact channels search --query <channel-name>`.
   Send file-backed parts in order with
   `hermes send --to buzz:<channel-id> --file <part-file> --json` - not the
   bare `buzz` CLI for sending. A cron-triggered run has no
   `BUZZ_PRIVATE_KEY` in its terminal-tool environment (hermes-agent's own
   GHSA-rhgp-j443-p4rf scrub only carves out `BUZZ_*` for a session whose
   platform is literally `buzz`), so `buzz messages send` fails there even
   with correct credentials configured; `hermes send` reloads
   `~/.hermes/.env` from disk at its own startup and works in both the cron
   and manual-rerun case, so use it unconditionally - see
   `buzz-multipart-delivery` for the full rationale and the 60,000-byte
   per-part budget (Buzz's real hard limit is 65,536 bytes).
7. **Verify external state before claiming success.** Read the channel
   back with
   `buzz --format compact messages get --channel <channel-id> --limit <enough>`
   and match every returned event ID and content section. A `"success":
   true` send result only proves submission, not visible publication. This
   readback step has no `hermes`-native equivalent yet, so it still uses
   the bare `buzz` CLI - it works for a manual rerun (session platform is
   `buzz`) but not from a cron-triggered run. In that case, report the
   `message_id` from each send as the strongest available evidence and say
   plainly that readback wasn't performed, rather than skipping this
   silently.
8. **Close the request concisely.** State that publication was verified
   and repeat any snapshot caveat; do not duplicate the full report in
   the requesting channel.

## Pitfalls

- Never describe a later compiled file as the failed run's exact data;
  compiler output is time-bounded and may have changed after repair.
- Never send a second copy from a scheduled invocation whose final
  response is already configured for delivery; that creates duplicate
  reports.
- Never trust message order or completeness from send responses alone;
  verify the destination channel because multipart sends can truncate,
  reorder, or partially fail.
- Never improvise an external host for report artifacts. Test currently
  available first-party attachment/upload paths and verify retrieval; if
  none works, retain the artifact locally and ask the recipient how to
  proceed.
