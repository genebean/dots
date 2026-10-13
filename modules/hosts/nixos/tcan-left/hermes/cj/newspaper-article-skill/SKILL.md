---
name: file-newspaper-article
description: "File an official-briefing or official-statement article on genebean/newspaper for content that already has Leo's and Jed's sign-off."
version: 1.0.0
---

# File a newspaper article

Use this after a briefing or statement already has both Leo's
detail-level sign-off and Jed's high-level approval, and has already been
delivered (in `#press-room` for a briefing, or wherever a statement is
distributed). This repo files the already-approved record - it is not
where approval happens, and it's not a drafting space. See AGENTS.md for
the full boundary this operates inside; nothing here changes who may
approve content or when you're allowed to say it, only how it gets
recorded once you have.

## What's already set up for you

- `git` and `tea` are on your `PATH`.
- `tea` is already logged in as `forgejo` against
  `https://git.home.technicalissues.us` (registered at container start by
  a systemd service using your own `hermes-cj` credential) - you don't
  need to log in yourself, and you have no other Forgejo credential to
  reach for.
- Your working directory persists across runs - clone once, reuse it.

## Which record type

Two directories, both yours, never Danny's `independent-reporting/`:

- `official-briefing/` - a press-room briefing, `author` is your own
  name (the press secretary role), `distribution.buzz.mode: full`.
- `official-statement/` - an administration statement, `author` is the
  originating institutional title (e.g. "Office of the Chief of Staff"),
  not a person's name, `distribution.buzz.mode: teaser`.

Each directory's own `TEMPLATE/article.md` documents its exact
convention - read it fresh each time rather than relying on this skill's
memory of it, in case it's changed.

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
3. **Copy the template** for whichever of your two record types this is:
   ```
   cp -r newspaper/articles/<official-briefing|official-statement>/TEMPLATE \
         newspaper/articles/<official-briefing|official-statement>/<YYYY-MM-DD>-<short-slug>
   ```
4. **Fill in `article.md`'s frontmatter and body** per that directory's
   own template conventions (see "Which record type" above). The content
   should match what was actually approved and delivered - this is a
   record of that, not a new draft; don't introduce wording that wasn't
   part of what Leo and Jed signed off on.
   - `id` is permanent - once set, never reused or recycled even if the
     piece is later withdrawn.
   - `distribution.buzz.message_url` only gets filled in once the Buzz
     message actually exists - it already does, since you're filing this
     after delivery, not before.
   - Leave `corrections.md` from the template as-is (no corrections yet)
     unless this article is itself issuing a correction to a prior one -
     see the template's own instructions for that shape.
5. **Commit, push, open the PR**:
   ```
   git -C newspaper add articles/<type>/<YYYY-MM-DD>-<short-slug>
   git -C newspaper commit -m "<short, factual summary of the article>"
   git -C newspaper push -u origin article/<YYYY-MM-DD>-<short-slug>
   tea pr create --login forgejo --repo genebean/newspaper \
     --head article/<YYYY-MM-DD>-<short-slug> --base main \
     --title "<same short summary>" \
     --description "<one or two sentences - what this covers and that it reflects already-approved, already-delivered content>"
   ```
6. **Say so** in `#senior-staff` or `#news-editors` - a PR link, not just
   silence - so Jed knows there's something waiting on his review.

## Boundaries (see AGENTS.md for the full list)

- Only `articles/official-briefing/` and `articles/official-statement/` -
  never `independent-reporting/`, Danny's record type. This is enforced
  two ways now, not just by review: Jed's required approval on every PR,
  and a CI check (`enforce-article-ownership`) that fails your PR
  automatically if it touches anything outside your own two directories.
- File only content that already has both Leo's and Jed's sign-off and
  has already been delivered - this repo isn't where that approval
  happens.
- One article per PR. Don't bundle multiple unrelated pieces together.
- Never push directly to `main` - branch protection blocks it anyway, but
  don't rely on that; always go through a branch and PR.
