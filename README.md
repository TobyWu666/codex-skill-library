# Codex Skill Library

Personal Codex skills.

## Skills

- `publish-static-site`: publish a local static website folder to GitHub Pages.
- `web-design-engineer`: build high-quality visual web artifacts.

## Install a skill

Copy a skill folder into your local Codex skills directory:

```bash
mkdir -p ~/.codex/skills
cp -R skills/publish-static-site ~/.codex/skills/
```

To install all skills from this library:

```bash
mkdir -p ~/.codex/skills
cp -R skills/* ~/.codex/skills/
```

Restart Codex after adding or updating skills.

## Sync local and GitHub skills

Run the sync script from this repository:

```bash
scripts/sync_skills.sh
```

It will:

- copy local third-party skills missing from this library into `skills/`
- copy library skills missing from `~/.codex/skills` into the local skills directory
- commit and push newly added local skills to GitHub

It does not overwrite same-named skills.
