---
name: github-pages-custom-domain
description: Configure, change, diagnose, and repair GitHub Pages custom domains and HTTPS. Use when the user asks to connect a GitHub Pages site to a custom domain or subdomain, change a Pages URL, set DNS/CNAME records, enable HTTPS enforcement, troubleshoot "The certificate does not exist yet", or fix GitHub Pages custom domain certificate/DNS issues.
---

# GitHub Pages Custom Domain

## Overview

Use this skill to move a GitHub Pages site from the default `*.github.io` URL to a custom domain, especially a subdomain such as `scalescout.tobywu.org`, and to diagnose the HTTPS certificate lifecycle when GitHub Pages says the certificate does not exist yet.

## Inputs To Establish

- GitHub repository in `OWNER/REPO` form.
- Desired domain or subdomain.
- DNS host/provider and whether it uses a proxy layer, such as Cloudflare.
- GitHub Pages source branch/folder and whether the site already builds successfully.

## Standard Workflow

1. Check current Pages state:

   ```bash
   gh api repos/OWNER/REPO/pages
   gh api repos/OWNER/REPO/pages/health
   ```

2. Tell the user what DNS record they need before or while setting Pages:

   - Subdomain: create a `CNAME` record from the subdomain label to `OWNER.github.io`.
   - Apex/root domain: use GitHub Pages apex records from GitHub's current docs; verify before giving exact IPs.
   - Cloudflare: set Proxy status to DNS only while GitHub issues the certificate. Proxy can be re-enabled later only if the user understands the TLS/proxy tradeoffs.

3. Verify DNS from the terminal:

   ```bash
   dig DOMAIN CNAME +noall +answer
   dig DOMAIN A +noall +answer
   dig DOMAIN AAAA +noall +answer
   dig DOMAIN CAA +noall +answer
   ```

4. Set the custom domain:

   ```bash
   gh api -X PUT repos/OWNER/REPO/pages -f cname=DOMAIN
   ```

5. Check certificate state and try to enforce HTTPS:

   ```bash
   gh api repos/OWNER/REPO/pages
   gh api -X PUT repos/OWNER/REPO/pages -F https_enforced=true -f cname=DOMAIN
   ```

6. Verify the public site:

   ```bash
   curl -I http://DOMAIN/
   curl -I https://DOMAIN/
   ```

## When HTTPS Is Stuck

If DNS is correct but GitHub keeps returning `The certificate does not exist yet`, reset the Pages custom domain. This forces GitHub to re-run the Pages certificate provisioning path.

Use the bundled script when available:

```bash
scripts/reset_pages_domain.sh OWNER/REPO DOMAIN --enforce
```

Manual equivalent:

```bash
tmp_json="$(mktemp)"
printf '{"cname":null}\n' > "$tmp_json"
gh api -X PUT repos/OWNER/REPO/pages --input "$tmp_json"
rm -f "$tmp_json"

gh api -X PUT repos/OWNER/REPO/pages -f cname=DOMAIN
gh api repos/OWNER/REPO/pages
gh api -X PUT repos/OWNER/REPO/pages -F https_enforced=true -f cname=DOMAIN
```

Notes:

- Do not rely on `-f cname=` to clear the domain; use JSON `{"cname":null}`.
- If GitHub still reports `certificate_not_yet_created` or similar after reset, wait and re-check. Certificate issuance often takes minutes but can take longer.
- If a CAA record exists, confirm it allows GitHub's certificate authority. If unsure, inspect current GitHub documentation before advising changes.

## Final Report

When done, report:

- GitHub repo and custom domain.
- DNS result, especially CNAME target or apex records.
- `https_certificate.state` and `https_enforced`.
- HTTP and HTTPS verification results.
- Any remaining wait state, DNS/provider action, or risk.
