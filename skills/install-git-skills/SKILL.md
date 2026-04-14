---
name: install-git-skills
description: Use when adding a new Git repository as a skill source for the current project or user-level .claude/skills directory. Use when the user provides a repo URL or owner/repo shorthand to install skills from.
license: MIT
compatibility: Requires bash, git, and curl.
---

# Install Git Skills

Creates a `.gs-meta` source file for a Git repository and immediately installs its skills.

## Parameters

| Parameter | Description |
|-----------|-------------|
| `<repo>` | _(required)_ GitHub shorthand (`owner/repo`) or full Git URL |
| `--path=` | Subfolder within the repo to install from (default: repo root) |
| `--name=` | Override the source name used in the `.gs-meta` filename (default: last segment of repo) |
| `--allow=` | Comma-separated folder names to install; all others skipped |
| `--deny=` | Comma-separated folder names to skip; all others installed |
| `--global` | Install to `~/.claude/skills` instead of `pwd/.claude/skills` |

## Usage

Run the script with the repo and any parameters the user provided:

```bash
bash ~/.claude/skills/install-git-skills/install.sh <repo> [options]
```

After installing, reload skills in your agent (e.g. `/reload-plugins` for Claude Code).

## Examples

Install all skills from a GitHub repo:
```bash
bash ~/.claude/skills/install-git-skills/install.sh googleworkspace/cli --path=skills
```

Install only specific skills:
```bash
bash ~/.claude/skills/install-git-skills/install.sh googleworkspace/cli --path=skills --allow=gws-gmail,gws-calendar
```

Install globally from a full URL:
```bash
bash ~/.claude/skills/install-git-skills/install.sh https://gitlab.com/owner/repo --path=skills --global
```

## Notes

- Creates a `.<name>.gs-meta` file in the target skills directory
- Errors if the `.gs-meta` file already exists — use `update-git-skills` to update existing sources
- Calls `update-git-skills` internally after creating the metadata file
- Only one of `--allow` or `--deny` may be set
