# Forgejo API publication fallback

Use this when the configured `tea` login is authenticated but noninteractive
Git transport cannot update the article branch. Keep credentials inside `tea`;
never print, copy, or embed the token.

## Read the current branch copy

Fetch each file through the contents endpoint and retain its blob `sha`. An
update with a stale SHA is rejected, which prevents silently overwriting a
newer edit.

```sh
tea api -l forgejo -r genebean/newspaper \
  '/repos/{owner}/{repo}/contents/<path>?ref=article%2F<slug>' \
  -o <scratch-json>
```

## Create a remote branch and files

```sh
tea api -l forgejo -r genebean/newspaper -X POST \
  /repos/{owner}/{repo}/branches \
  -f new_branch_name=article/<slug> \
  -f old_branch_name=main

content=$(base64 -w0 <path>)
tea api -l forgejo -r genebean/newspaper -X POST \
  '/repos/{owner}/{repo}/contents/<path>' \
  -f branch=article/<slug> \
  -f message='<factual commit message>' \
  -f content="$content"
```

Repeat the contents call for `article.md` and `corrections.md`, then open the
PR normally. One API commit per file is acceptable; one article per PR is the
boundary that matters.

## Revise an existing file

```sh
content=$(base64 -w0 <path>)
tea api -l forgejo -r genebean/newspaper -X PUT \
  '/repos/{owner}/{repo}/contents/<path>' \
  -f branch=article/<slug> \
  -f message='<revision message>' \
  -f sha=<current-blob-sha> \
  -f content="$content"
```

Read the file back through the contents endpoint, decode its base64 content,
and compare the required properties against the local edit.

## Verify CI and retrieve a failing job log

```sh
tea actions runs list --login forgejo --repo genebean/newspaper --output json

tea api -l forgejo -r genebean/newspaper \
  '/repos/{owner}/{repo}/actions/runs/<run-id>/jobs'

tea api -l forgejo -r genebean/newspaper \
  '/repos/{owner}/{repo}/actions/jobs/<job-id>/logs' \
  -o <scratch-log>
```

Wait for the workflows attached to the latest branch head. Ignore cancelled
runs superseded by a newer commit. Completion requires the latest ownership
and site-build runs to succeed, the PR to remain mergeable, and its file list
to contain only the intended article directory.
