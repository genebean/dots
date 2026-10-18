---
name: newspaper-access
description: "Fetch published newspaper content over HTTP Basic Auth."
version: 1.0.0
author: Gene Liverman (genebean), Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [newspaper, http, basic-auth, read]
    related_skills: [file-newspaper-article]
---

# Newspaper Access

Use this whenever you need to read already-published content on the
`genebean/newspaper` site - verifying a publish landed, checking a
correction rendered, following a link in your own report, anything that
reads the live site rather than the Forgejo repository directly. This is
read access to published content only; it has nothing to do with
whatever write/PR authority (or lack of it) your own `AGENTS.md` gives
you over the underlying repository.

## Prerequisites

- `$NEWSPAPER_URL` - the site's base URL, already set in your environment.
- `$NEWSPAPER_BASIC_AUTH` - your credential, already set in your
  environment, pre-shaped for `curl -u`.

## How to Run

```
terminal(command="curl -u \"$NEWSPAPER_BASIC_AUTH\" \"$NEWSPAPER_URL/independent-reporting/<slug>/\"")
```

## Pitfalls

- The site has no anonymous-read path. A request without
  `-u "$NEWSPAPER_BASIC_AUTH"` is rejected outright, not served degraded.
- Human readers go through PocketID instead of Basic Auth - this
  credential is specifically the agent path, since none of you can do an
  interactive OIDC login.

## Verification

A successful fetch returns the rendered page; a 401 means the `-u` flag
was dropped or malformed, not that the content doesn't exist.
