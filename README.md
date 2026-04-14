# agent-skills

A personal collection of agent skills by [cytoph](https://github.com/cytoph).

These skills follow the [Agent Skills specification](https://agentskills.io/specification) so they can be used by any skills-compatible agent, including Claude Code and Codex CLI.

## Table of Contents

- [Installation](#installation)
- [Skills](#skills)

## Installation

### Global install

Makes all skills available in every project.

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/cytoph/agent-skills/main/scripts/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/cytoph/agent-skills/main/scripts/install.ps1 | iex
```

**Windows (CMD):**
```cmd
curl -fsSL https://raw.githubusercontent.com/cytoph/agent-skills/main/scripts/install.cmd -o install.cmd && install.cmd && del install.cmd
```

### Project-level install

To install for a single project only, download the [appropriate script file](scripts/) into the folder that contains your `.claude` directory, then run it passing `--local`:

**macOS / Linux:** `bash install.sh --local`

**Windows (PowerShell):** `.\install.ps1 -Local`

**Windows (CMD):** `install.cmd --local`

After installing, reload skills in your agent (e.g. `/reload-plugins` for Claude Code).

## Skills

### `install-git-skills`

Installs skills from a Git repository into your project or user-level `.claude/skills` directory. Point it at any repo and optionally filter which skill folders to install. Once invoked, it creates a `.gs-meta` source file and immediately fetches the skills — after that, `update-git-skills` takes over for future updates.

### `update-git-skills`

Checks all registered `.gs-meta` sources against their upstream repos and downloads updates when something has changed. Run it periodically to keep your installed skills current, or after manually adding a new `.gs-meta` file. Supports updating project-level and user-level skills independently.
