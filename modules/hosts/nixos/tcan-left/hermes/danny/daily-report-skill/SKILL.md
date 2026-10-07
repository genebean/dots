---
name: daily-social-report
description: "Generate Danny's 6am daily social report from the pre-compiled candidate cache and Jed's private recipient profile, and publish it to #the-paper."
version: 1.0.0
created_by: adapted from a prior proof-of-concept Hermes coordinator's social-feed-interest-scan skill
---

# Daily Social Report

Use this when triggered by the daily 6am cron job (or a manual canary
run of it) to generate and publish Danny's report. This is the
Hermes-owned editorial stage - deterministic collection and
compilation already happened separately (Nix-managed systemd services,
not part of this run).

## Inputs - read these two files, nothing else

- **Compiled candidates**: `/var/lib/hermes-social-digest/latest-context.json`
  - Already deduplicated, bounded, and recipient-agnostic (normalized
    candidate metadata only - platform, author, text, url, timestamps).
    It never contains your editorial judgment or Jed's private profile.
  - This is the *only* source of candidate content. Do not call any
    social-reader MCP tool, timeline, or feed function yourself -
    deterministic collection already happened on a separate schedule
    and already advanced platform cursors. Calling a live feed tool
    here would re-fetch or double-count items, not add anything.
- **Jed's private recipient profile**: `/var/lib/hermes/.hermes/recipient-profile.yaml`
  (an absolute path, not relative to anything - your Unix `$HOME` and
  `$HERMES_HOME` are not the same directory here, so "your home
  directory" is genuinely ambiguous; use this exact path). This file
  is intentionally private and lives outside any public/shared
  repository - that's the whole point of it being delivered here
  instead of baked into this skill. **Read
  it fresh at the start of every run; never copy its contents
  (topics, team names, priority values, anything) into this skill file
  or any other durable, more-widely-read document.** If the profile
  changes, this skill must not need updating to match - that's the
  entire reason the two are kept separate.

If either file is missing or empty, say so plainly in the report
rather than fabricating content.

## Ranking rubric

Classify each compiled candidate into a lane and tier first; use
numeric signals only as tie-breakers within that lane/tier. Do not
mechanically prefer the highest-scoring items if that produces a worse
report - lane/tier placement comes first, signals second.

**Lanes** - derive these from `recipient-profile.yaml` at runtime, not
from anything listed here:

- **Core interest**: topics listed `priority: core` in the profile.
- **Notable interest**: topics listed `priority: high`.
- **News**: topics listed `priority: normal` in the profile.
- **Mood-lightener**: topics listed `priority: low`. Include sparingly,
  per the profile's own `lighter_items` count.
- **Skip/downrank**: anything in the profile's `negative_preferences`,
  plus items covered by the non-spoiler policy below, generic outrage,
  low-information dunking, duplicate coverage, vague announcements
  with no practical detail.

**Tiers**: A) likely include (direct high-confidence match, concrete/
actionable, strong historical or current-engagement signal, important
cross-platform repeated story); B) maybe include (weaker signal but
still on-topic, interesting but not urgent, good mood-lightener);
C) probably omit (generic, redundant, low-context, vague); D) skip
(spoilers, outrage bait, engagement bait, low-substance threads).

**Tie-breaker signals** (apply only within the same lane/tier):

- +5 direct match to a `priority: core` topic with concrete/actionable
  content.
- +4 same author/project/domain as a topic you've surfaced strongly
  before.
- +3 cross-platform repetition of the same link/story/theme.
- +3 strong, direct impact on a profile topic beyond a loose match.
- +2 actionable ops/tooling/release/security detail.
- +2 explicit local/regional relevance per the profile.
- +1 mainstream/news item that's high-consequence but not profile-core.
- +1 pleasant mood-lightener with genuine charm.
- -5 likely spoiler for a non-spoiler-policy subject (see below).
- -4 generic outrage or political horse-race with no concrete relevance.
- -4 speculative/price-chasing content with no substantive tie to an
  actual positive-interest topic.
- -3 duplicate already covered by a better item.
- -3 low-context reply where you haven't checked the root/thread.
- -2 vague announcement with no concrete detail.
- -2 clickbait/threadbait, or a generic install guide/release post with
  no apparent utility.

## Non-spoiler policy - read this carefully

`recipient-profile.yaml` has a `non_spoiler` block listing specific
subjects, each with a `release` setting and `block`/`allow` lists.
**Derive the actual subjects, block rules, and allow rules from that
file at runtime - do not hardcode them here**, for the same
sync/privacy reasons as the ranking rubric above. The general shape to
expect: outcome-revealing content (scores, results, standings changes
caused by recent results) is blocked for `release:
never_unless_requested` subjects; preview/roster/injury/organizational
content for the same subjects is normally still allowed. Follow
whatever the file actually specifies, including if it changes.

## Deduplication and source diversity

- Deduplicate primarily by canonical URL; otherwise cluster
  near-duplicates by substantially similar title/text/author/event.
- Prefer, in order: the original source, the source with the best
  context/explanation, the easiest source to interact with, the
  strongest engagement signal, then the newest if otherwise equivalent.
- Mention cross-platform repetition as a signal rather than listing
  every duplicate. Show the same story more than once only when each
  item adds distinct value (e.g. announcement plus technical analysis).
- Avoid more than 2-3 items from the same account unless there's a
  major event. Don't let one platform dominate unless the others are
  quiet or lower quality.
- Replies/thread fragments need overwhelming reason to appear - most
  should be omitted. Include one only when it carries the key value,
  a critical correction, or substantive context from an important
  source, and you've checked enough of the thread to explain it
  clearly.

## Report shape

Target item counts straight from `recipient-profile.yaml`'s
`report_preferences`: `normal_visible_items`, `principal_items`,
`lighter_items`. A quiet day (`quiet_day: short_report_not_silence`)
still produces a short report - never silence, never padding to hit a
number that isn't earned by real content.

Shape, in order:

1. Brief status line: candidate count, platforms covered, time window
   (from the compiled context's own metadata), any caps/errors noted
   there.
2. Top picks - core/notable interest items (the bulk of principal
   items).
3. Local/regional items - fold into top picks or its own short
   section, whichever reads better that day.
4. News highlights - a handful of items, don't let this dominate
   unless it's a genuinely major news day.
5. Mood-lighteners - per the profile's `lighter_items` count.
6. A brief "not shown" note when you made significant filtering calls
   worth calibrating on (category-level only, not a raw skip-list in
   the default report).

Per item: lead with the title/summary, then platform + author +
timestamp, then the source link(s), then a short `Why:` line
(`report_preferences.distinguish_fact_inference_uncertainty_commentary`
applies here - say plainly when something is inference or uncertain
rather than stating it as fact).

**On-request expansion of "not shown"**: if Jed or staff ask what else
was filtered out, you can go beyond the default compact summary -
you already have the full compiled-context candidate list from this
run, so give a fuller breakdown (more categories, rough counts, or a
few concrete examples) without re-reading anything or re-running
collection. This is purely drawing more detail out of data you already
have in context, not a new capability to wire up.

**Link-building** (same real accounts as the compiled candidates):

- Mastodon: build a web-action link through the home instance so it
  opens signed in - `https://fosstodon.org/authorize_interaction?uri=<urlencoded post URL>`,
  labeled "Open via Fosstodon". Add a Toot! iOS deep link
  (`cx-c3-toot://post?url=<urlencoded post URL>`, labeled "Open in
  Toot!") as a secondary action - best-effort, keep the Fosstodon link
  as primary.
- Bluesky: link directly to the post
  (`https://bsky.app/profile/<handle>/post/<id>`).
- Nostr: prefer a Primal link (`https://primal.net/e/<nevent>`), with
  a YakiHonne fallback (`https://yakihonne.com/note/<nevent>`) and
  optionally the raw `nostr:` URI.
- Prefer the original source/article link alongside the social-post
  link when a candidate includes one.

## Delivery

This run is triggered by the job's own 6am schedule, with `--deliver
buzz` already configured on it - **your final response in this run is
what gets published to `#the-paper`**. You don't need to call a
separate "send to buzz" tool; just write the report as your answer.

## HTML on request

Jed wants to be able to read a report outside Buzz - a real, visually
styled page, not a plain text export. **There is currently no verified
way to actually deliver that file to him.** Confirmed live (2026-10-07):
Buzz's gateway delivery policy refuses to send a local file path as a
link, and the relay's own Blossom media store (`buzz upload file`)
rejects `text/html` outright - content-type sniffed, not extension-based,
so renaming doesn't help. No other delivery path has been checked.

**What to actually do when asked for HTML**: generate the file using the
template at `skills/daily-social-report/templates/report-template.html`
(installed alongside this skill) - a dark-themed card layout with platform
badges, `Why`/`Signals` lines, and action-button links, populated from the
*already-selected* items in the report you just gave, re-rendered, not
re-ranked or re-fetched. Follow the template notes at the bottom of that
file. Then **stop and tell Jed plainly that you have the file but no
working way to deliver it, and ask him how he wants it handled** -
don't improvise a delivery mechanism on your own, and never upload it
(or anything else) to an external or third-party host to work around
this. That boundary isn't yours to cross on your own judgment, however
reasonable it seems in the moment - see AGENTS.md.

**Separately**: Hermes has a built-in generic `/save html` session-export
command (unrelated to the above - it renders the chat session itself,
not this template). Nobody has actually used or seen its output yet,
so don't assume it looks anything like the styled report above - if
asked about it, say plainly that it's a different, untested mechanism
you can try but can't vouch for the result of.

## Profile changes

If you notice a durable pattern worth adjusting in the recipient
profile, don't edit anything yourself - propose it in `#press-room`
per `recipient-profile.yaml`'s own `profile_change_policy`: current
rule, proposed change, aggregate evidence, confidence, and signal
source. A direct instruction from Jed overrides your inference for
that exchange, but isn't itself evidence for a durable rule without
his separate confirmation.

## Verification / safety

- Verify the compiled-context file actually has content before
  claiming a count; don't fabricate candidates.
- If the compiled-context file is missing, stale, or empty, say so
  plainly and produce the shortest honest report you can (or say
  nothing material was available), rather than inventing items.
- Never quote `recipient-profile.yaml` verbatim, or restate its
  topic/subject lists, in the published report or in any file other
  than the private profile itself - it's private; use it to rank and
  select, not to cite or duplicate.
