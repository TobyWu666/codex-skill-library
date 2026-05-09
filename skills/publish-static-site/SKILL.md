---
name: publish-static-site
description: Publish a local static website folder to GitHub Pages. Use when the user asks to put local HTML/CSS/JS assets online, deploy a static landing page, create a GitHub repo for a local site, push local files to GitHub, enable GitHub Pages, or verify a GitHub Pages URL after deployment.
---

# Publish Static Site

## Overview

Publish a local static site with a clean GitHub repository, GitHub Pages workflow deployment, and post-deploy verification. Keep source folders tidy: never push an entire mixed workspace when only a site folder should be published.

## Preconditions

- Confirm the site folder contains the deploy root, usually `index.html` plus asset folders.
- Prefer a clean, dedicated repo folder if the source lives inside a larger workspace.
- Use `gh auth status` before creating repos or pushing.
- Use public repos for simple marketing pages unless the user requests private.
- Do not expose secrets, drafts, large build caches, or unrelated workspace files.

## Workflow

1. Inspect the local site folder.
   - Check files with `find <site> -maxdepth 2 -type f | sort`.
   - Confirm relative asset paths work from the deploy root.
   - If the source folder is nested inside a larger workspace, create a clean sibling publish folder and copy only required files.

2. Initialize or reuse a git repo.
   - If creating a new publish folder, run `git init -b main`.
   - Add a minimal `README.md` only if useful for the repository.
   - Commit the site files before creating the remote.

3. Add a GitHub Pages workflow.
   - Prefer `scripts/write_pages_workflow.sh <repo-dir>` from this skill.
   - Commit `.github/workflows/pages.yml`.
   - The workflow should deploy from repository root through GitHub Actions.

4. Create and push the GitHub repo.
   - If `gh repo view OWNER/REPO` succeeds, reuse it only after confirming it is the intended target.
   - Otherwise run:

```bash
gh repo create OWNER/REPO --public --source . --remote origin --push
```

   - If the user has not specified `OWNER/REPO`, infer the authenticated owner from `gh auth status` only when it is unambiguous, and choose a concise repo name from the site name.

5. Enable GitHub Pages.
   - After the repo exists, run:

```bash
gh api -X POST repos/OWNER/REPO/pages -f build_type=workflow
```

   - If it already exists, this may fail; then inspect it:

```bash
gh api repos/OWNER/REPO/pages
```

6. Watch deployment.
   - Check runs with `gh run list --repo OWNER/REPO --limit 5`.
   - If a run failed because Pages was not enabled, enable Pages with `gh api` and rerun:

```bash
gh run rerun RUN_ID --repo OWNER/REPO
gh run watch RUN_ID --repo OWNER/REPO --exit-status
```

7. Verify the public URL.
   - Read the final URL with:

```bash
gh api repos/OWNER/REPO/pages --jq '.html_url'
```

   - Confirm HTTP success:

```bash
curl -I https://OWNER.github.io/REPO/
```

   - Report the GitHub repo URL, Pages URL, and verification result.

## Pages Workflow

Use the helper script:

```bash
/Users/toby_wu_/.codex/skills/publish-static-site/scripts/write_pages_workflow.sh <repo-dir>
```

It writes `.github/workflows/pages.yml` with `actions/configure-pages`, `actions/upload-pages-artifact`, and `actions/deploy-pages`.

## Failure Handling

- `gh: command not found`: ask the user to install GitHub CLI and run `gh auth login`.
- `gh auth status` not logged in: ask the user to log in before continuing.
- `Resource not accessible by integration` in Actions: enable Pages locally via `gh api -X POST repos/OWNER/REPO/pages -f build_type=workflow`, then rerun the workflow.
- `HTTP 404` for Pages immediately after deploy: wait briefly, re-check `gh api repos/OWNER/REPO/pages`, then retry `curl -I`.
- Existing repo conflict: do not force push unless the user explicitly approves and the target repo is confirmed.

## Final Response

Keep the final short and include:

- Pages URL
- GitHub repo URL
- What was pushed or changed
- Whether deployment was verified with `HTTP 200`
