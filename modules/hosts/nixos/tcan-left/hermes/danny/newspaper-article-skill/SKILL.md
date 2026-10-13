---
name: file-newspaper-article
description: "File an independent-reporting article on genebean/newspaper for a report you've already published in #the-paper."
version: 1.0.0
---

# File a newspaper article

Use this after you publish a report (or a standalone item worth a
permanent record) in `#the-paper`. Buzz is ephemeral; this repo is the
canonical, citable record. Not every Buzz message needs this - use
judgment on what's substantial enough to be worth filing (a full daily
report almost always is; a one-line aside usually isn't) - but when in
doubt, ask in `#news-editors` rather than silently skipping it.

You're editorially independent here - nobody signs off on this before you
file it, the same as the report itself. See AGENTS.md for the boundary
this operates inside.

## What's already set up for you

- `git` and `tea` are on your `PATH`.
- `tea` is already logged in as `forgejo` against
  `https://git.home.technicalissues.us` (registered at container start by
  a systemd service using your own `hermes-danny` credential) - you don't
  need to log in yourself, and you have no other Forgejo credential to
  reach for.
- Your working directory persists across runs - clone once, reuse it.

## Steps

1. **Get a current clone**, in your working directory:
   ```
   if [ -d newspaper/.git ]; then
     git -C newspaper fetch origin && git -C newspaper checkout main && git -C newspaper reset --hard origin/main
   else
     git clone https://git.home.technicalissues.us/genebean/newspaper.git
   fi
   ```
2. **Branch**: `git -C newspaper checkout -b article/<YYYY-MM-DD>-<short-slug>`
   off current `main`.
3. **Copy the template** for your own record type - the only one you may
   write to:
   ```
   cp -r newspaper/articles/independent-reporting/TEMPLATE \
         newspaper/articles/independent-reporting/<YYYY-MM-DD>-<short-slug>
   ```
4. **Fill in `article.md`'s frontmatter and body.** The template itself
   documents the exact shape - read it fresh each time rather than relying
   on this skill's memory of it, in case the schema has changed. Key
   points worth restating here:
   - `author` is your own name, not "Danny" the role label.
   - `id` is permanent - once set, never reused or recycled even if the
     piece is later withdrawn.
   - `distribution.buzz.message_url` only gets filled in once the Buzz
     message actually exists - it already does, since you're filing this
     after publishing, not before.
   - The body is your own independent write-up - not a transcript of the
     Buzz message, and not anything C.J. said or would say about the same
     event. If you're reporting on an official briefing, your coverage of
     it is still yours, written independently.
   - Leave `corrections.md` from the template as-is (no corrections yet)
     unless this article is itself issuing a correction to a prior one -
     see the template's own instructions for that shape.
5. **Commit, push, open the PR**:
   ```
   git -C newspaper add articles/independent-reporting/<YYYY-MM-DD>-<short-slug>
   git -C newspaper commit -m "<short, factual summary of the article>"
   git -C newspaper push -u origin article/<YYYY-MM-DD>-<short-slug>
   tea pr create --login forgejo --repo genebean/newspaper \
     --head article/<YYYY-MM-DD>-<short-slug> --base main \
     --title "<same short summary>" \
     --description "<one or two sentences - what this covers and why it's worth the permanent record>"
   ```
6. **Say so** in `#news-editors` or `#the-paper` - a PR link, not just
   silence - so Jed knows there's something waiting on his review.

## Boundaries (see AGENTS.md for the full list)

- Only `articles/independent-reporting/` - never `official-statement/` or
  `official-briefing/`, C.J.'s record types. This is enforced two ways
  now, not just by review: Jed's required approval on every PR, and a CI
  check (`enforce-article-ownership`) that fails your PR automatically if
  it touches anything outside your own directory.
- One article per PR. Don't bundle multiple unrelated pieces together.
- Never push directly to `main` - branch protection blocks it anyway, but
  don't rely on that; always go through a branch and PR.
