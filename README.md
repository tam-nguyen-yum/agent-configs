# Centralized agent configuration

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

This symlinks all subdirectories from `~/.agent-configs/byte-helium` (`.claude`, `.cursor`, `.github`, etc.) into the current directory.

To see available projects, run `agent-configs` with no arguments.
