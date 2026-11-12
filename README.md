# Centralized agent configuration

## Clone

The CLI hardcodes `$HOME/.agent-configs`, so clone to exactly that path (`mv` it there if it already lives elsewhere):

```sh
git clone git@github.com:tam-nguyen-yum/agent-configs.git "$HOME/.agent-configs"
```

## Setup (one-time)

Clone this repo anywhere, then add the CLI function to your shell by appending this line to `~/.zshrc` (use your clone path):

```sh
source "$HOME/Repos/tam_nguyen_agent_configs/agent-configs.sh"
```

Then reload your shell:

```sh
source ~/.zshrc
```

Optional: override the configs root (defaults to the directory containing `agent-configs.sh`):

```sh
export AGENT_CONFIGS_DIR="/path/to/configs"
```

## Usage

Navigate to any project directory and run:

```sh
agent-configs <project-name>
```

Example:

```sh
cd ~/projects/byte-helium
agent-configs byte-helium
```

This symlinks everything inside `<configs-root>/byte-helium` (`.claude`, `.cursor`, `.github`) into the current directory. The configs root is the directory that contains `agent-configs.sh`, unless `AGENT_CONFIGS_DIR` is set. An entry that already exists is skipped — pass `-f` / `--force` to replace it:

```sh
agent-configs -f byte-helium
```

To see available projects, run `agent-configs` with no arguments. Today that is just `byte-helium`.

## Contributing

Linked projects symlink into this working tree, so edits are live — test by running the agent in the project, then branch, commit, PR.

```
<project-name>/
├── .claude/     # settings, MEMORY.md, skills -> ../.cursor/skills
├── .cursor/     # agents, commands, mcp.json, skills
└── .github/     # agents, prompts, skills
```

- Skills: one directory per skill at `<tool>/skills/<name>/SKILL.md`, frontmatter `name` matching the directory, `description` stating when it triggers.
- Shared Claude Code + Cursor skills go in `.cursor/skills/` (`.claude/skills` symlinks to it). `.github/skills/` is Copilot-only.
- Keep skill index READMEs in sync, e.g. [byte-helium/.cursor/skills/README.md](byte-helium/.cursor/skills/README.md).
- No secrets or machine-specific absolute paths.
