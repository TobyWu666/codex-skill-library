#!/usr/bin/env bash
set -euo pipefail

repo_dir="${1:-.}"
workflow_dir="$repo_dir/.github/workflows"
workflow_file="$workflow_dir/pages.yml"

mkdir -p "$workflow_dir"

cat > "$workflow_file" <<'YAML'
name: Deploy GitHub Pages

on:
  push:
    branches:
      - main
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Configure Pages
        uses: actions/configure-pages@v5
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: .
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
YAML

printf 'Wrote %s\n' "$workflow_file"
