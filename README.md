# Centralized agent configuration

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

This symlinks all subdirectories from `<configs-root>/byte-helium` (`.claude`, `.cursor`, `.github`, etc.) into the current directory. The configs root is the directory that contains `agent-configs.sh`, unless `AGENT_CONFIGS_DIR` is set.

To see available projects, run `agent-configs` with no arguments.
