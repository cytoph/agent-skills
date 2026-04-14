---
name: update-git-skills
description: Use when updating externally-sourced skills from Git repositories in the current project or user-level .claude/skills directory. Use when skills may be outdated or after adding a new .gs-meta source file.
license: MIT
compatibility: Requires bash, git, and curl.
---

# Update Git Skills

Checks `*.gs-meta` source files against their upstream Git repos and downloads updates when the SHA has changed.

## Parameters

| Parameter | Description |
|-----------|-------------|
| _(none)_ | Update all sources in `pwd/.claude/skills` |
| `--global` | Update all sources in `~/.claude/skills` |
| `--only=name1,name2` | Limit to named sources (matches the `.<name>.gs-meta` filename) |

## Usage

Run the script, passing any parameters the user provided:

```bash
bash ~/.claude/skills/update-git-skills/update.sh [--global] [--only=name1,name2]
```

After updating, run `/reload-plugins` to pick up changes.

## Adding a Skill Source

Create a `.<name>.gs-meta` file in `.claude/skills/`:

```
repo=owner/repo
path=relative/path/to/skills/folder
sha=
allow=folder1,folder2
```

- `repo` — GitHub shorthand (`owner/repo`) or full Git URL (`https://gitlab.com/owner/repo`, `git@...`)
- `path` — subfolder within the repo whose contents are copied to `.claude/skills/`
- `sha` — leave empty on first add; filled in automatically after install
- `allow` — _(optional)_ comma-separated folder names to install; all others skipped
- `deny` — _(optional)_ comma-separated folder names to skip; all others installed

Only one of `allow` or `deny` may be set. If both are present the script logs an error for that source and continues with the others.

**Example** — `.gws-cli.gs-meta`:
```
repo=googleworkspace/cli
path=skills
sha=
allow=gws-gmail,gws-calendar
```

## Notes

- Only tracks the `main` branch
- Uses `git ls-remote` for SHA check (no download if already up to date)
- Clones with `--filter=blob:none` where supported; falls back to plain `--depth 1`
- Skills from different repos sharing a folder name will overwrite each other — avoid naming conflicts
- This skill itself is not managed by the script
