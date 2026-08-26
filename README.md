# Centralized agent configuration

## Clone

The CLI hardcodes `$HOME/.agent-configs`, so clone to exactly that path (`mv` it there if it already lives elsewhere):

```sh
git clone git@github.com:tam-nguyen-yum/agent-configs.git "$HOME/.agent-configs"
```

## Setup (one-time)

Add the CLI function to your shell by appending this line to `~/.zshrc`:

```sh
source "$HOME/.agent-configs/agent-configs.sh"
```

Then reload your shell:

```sh
source ~/.zshrc
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

This symlinks everything inside `~/.agent-configs/byte-helium` (`.claude`, `.cursor`, `.github`) into the current directory. An entry that already exists is skipped — pass `-f` / `--force` to replace it:

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
