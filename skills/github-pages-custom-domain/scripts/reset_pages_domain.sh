#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: reset_pages_domain.sh OWNER/REPO DOMAIN [--enforce]

Removes and re-adds a GitHub Pages custom domain to retrigger certificate
provisioning. Add --enforce to also try enabling HTTPS enforcement.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage >&2
  exit 2
fi

repo="$1"
domain="$2"
enforce="${3:-}"

if [[ "$repo" != */* ]]; then
  echo "error: repo must be OWNER/REPO" >&2
  exit 2
fi

if [[ -n "$enforce" && "$enforce" != "--enforce" ]]; then
  echo "error: unknown option: $enforce" >&2
  usage >&2
  exit 2
fi

tmp_json="$(mktemp)"
trap 'rm -f "$tmp_json"' EXIT

printf '{"cname":null}\n' > "$tmp_json"

echo "Clearing custom domain for $repo..."
gh api -X PUT "repos/$repo/pages" --input "$tmp_json" >/dev/null

echo "Re-adding custom domain: $domain"
gh api -X PUT "repos/$repo/pages" -f "cname=$domain" >/dev/null

echo "Current Pages state:"
gh api "repos/$repo/pages"

if [[ "$enforce" == "--enforce" ]]; then
  echo "Trying to enable HTTPS enforcement..."
  gh api -X PUT "repos/$repo/pages" -F https_enforced=true -f "cname=$domain"
fi
