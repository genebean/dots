---
name: newspaper-editorial-review
description: "Revise newspaper articles and verify publication quality."
version: 0.1.0
author: Jed, Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [newspaper, editing, forgejo, verification]
    related_skills: [file-newspaper-article, social-report-publication-review]
---

# Newspaper Editorial Review

Use this to revise an open newspaper article after editorial feedback and to
prove the revised branch is publishable. It supplements the filing skill: this
skill governs revision quality, remote updates, and verification.

## When to Use

- Revising an open newspaper article or article PR.
- Applying editorial style feedback across frontmatter, body, and corrections.
- Diagnosing a newspaper ownership or site-build failure caused by article
  content, metadata, or slugging.

Do not use it to alter official statement or briefing records owned by another
role.

## Procedure

1. **Read the remote revision before editing.** Inspect the PR head, exact file
   list, current `article.md`, current `corrections.md`, and the latest template.
   Work from the branch copy rather than a stale local assumption.
2. **Preserve the record while applying the requested edit.** Keep the
   permanent `id`, published timestamp, selected items, evidence links, and
   distribution link unless the feedback specifically changes one. Increment
   `revision` and set `revision_at` to a quoted RFC 3339 string.
3. **Apply the newspaper punctuation standard.** Prefer ASCII when it carries
   the same meaning: straight apostrophes and quotation marks, `-` for ordinary
   dashes and ranges, and `|` for compact metadata or link separators. Retain
   Unicode only when it materially preserves a proper name, language,
   technical symbol, or source text. Scan both Markdown files after editing;
   account for every remaining non-ASCII character rather than sampling a few
   examples.
4. **Update the existing branch.** Use the normal Git push path when it is
   authenticated. When the configured `tea` login works but Git transport does
   not, use `references/forgejo-api-publication.md`; never expose the token or
   stop at an unpushed local commit.
5. **Verify remote state, not just the write response.** Read both files back
   from the PR branch and compare the requested properties. Confirm the remote
   head changed, the PR lists only the intended article directory, the PR is
   mergeable, and both ownership and site-build workflows succeeded. If a
   workflow fails, read the job log, repair the actual schema, ownership, slug,
   or rendering cause, and wait for the replacement run.
6. **Report the revision concisely.** State what changed, the revision number,
   the concrete verification performed, and whether the PR is ready for
   review. Do not call an article live while approval and merge are still
   pending.

## Pitfalls

- Use a title-specific remainder after a leading date in recurring article
  directories - Zola removes the date when deriving the public path, so a
  repeated generic remainder collides with the prior edition.
- Quote `revision_at` - YAML may otherwise deserialize and re-emit the timestamp
  in a form the site's date filter rejects.
- Read back API writes - a successful contents call proves submission, not
  that the branch now contains the intended bytes.
- Inspect both required workflows - ownership success does not prove the site
  renders, and a successful build does not prove path ownership.

## Verification

A revision is complete only when the branch copy matches the requested style
and content, all remaining non-ASCII characters are intentional, the PR file
list is exact, the PR is mergeable, and both required workflows pass.
