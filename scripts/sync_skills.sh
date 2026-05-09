#!/usr/bin/env bash
set -euo pipefail

library_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
local_skills="${CODEX_HOME:-$HOME/.codex}/skills"
library_skills="$library_root/skills"
dry_run=0
pull_remote=1
push_remote=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=1
      ;;
    --no-pull)
      pull_remote=0
      ;;
    --no-push)
      push_remote=0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      exit 2
      ;;
  esac
  shift
done

if [[ ! -d "$local_skills" ]]; then
  printf 'Local skills directory not found: %s\n' "$local_skills" >&2
  exit 1
fi

mkdir -p "$library_skills"

if [[ "$pull_remote" -eq 1 && "$dry_run" -eq 0 ]]; then
  if [[ -n "$(git -C "$library_root" status --short)" ]]; then
    printf 'Library repo has uncommitted changes; aborting before pull.\n' >&2
    git -C "$library_root" status --short >&2
    exit 1
  fi
  git -C "$library_root" pull --ff-only origin main
fi

is_third_party_skill() {
  local path="$1"
  local name
  name="$(basename "$path")"
  [[ -f "$path/SKILL.md" ]] || return 1
  [[ "$name" != .* ]] || return 1
  [[ "$name" != "codex-primary-runtime" ]] || return 1
}

copy_skill() {
  local src="$1"
  local dest="$2"
  if [[ "$dry_run" -eq 1 ]]; then
    printf 'Would copy %s -> %s\n' "$src" "$dest"
  else
    cp -R "$src" "$dest"
  fi
}

added_to_library=()
installed_locally=()

for skill_dir in "$local_skills"/*; do
  [[ -d "$skill_dir" ]] || continue
  if ! is_third_party_skill "$skill_dir"; then
    continue
  fi
  skill_name="$(basename "$skill_dir")"
  if [[ ! -e "$library_skills/$skill_name" ]]; then
    copy_skill "$skill_dir" "$library_skills/$skill_name"
    added_to_library+=("$skill_name")
  fi
done

for skill_dir in "$library_skills"/*; do
  [[ -d "$skill_dir" ]] || continue
  [[ -f "$skill_dir/SKILL.md" ]] || continue
  skill_name="$(basename "$skill_dir")"
  if [[ ! -e "$local_skills/$skill_name" ]]; then
    copy_skill "$skill_dir" "$local_skills/$skill_name"
    installed_locally+=("$skill_name")
  fi
done

if [[ "$dry_run" -eq 0 && "${#added_to_library[@]}" -gt 0 ]]; then
  git -C "$library_root" add skills
  git -C "$library_root" commit -m "Sync local Codex skills"
  if [[ "$push_remote" -eq 1 ]]; then
    git -C "$library_root" push origin main
  fi
fi

printf 'Added to library: %s\n' "${added_to_library[*]:-none}"
printf 'Installed locally: %s\n' "${installed_locally[*]:-none}"

if [[ "$dry_run" -eq 1 ]]; then
  printf 'Dry run complete. No files changed.\n'
fi
