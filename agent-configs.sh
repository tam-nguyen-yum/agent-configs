#!/usr/bin/env bash
# Usage: agent-configs [-f] <project-name>
# Symlinks all subdirectories from ~/.agent-configs/<project-name> into the current directory.
# Use -f / --force to replace existing files or symlinks.

agent-configs() {
  local force=0
  local args=()

  for arg in "$@"; do
    case "$arg" in
      -f|--force) force=1 ;;
      *) args+=("$arg") ;;
    esac
  done

  local project="${args[1]}"
  local configs_dir="$HOME/.agent-configs"
  local source_dir="$configs_dir/$project"

  if [[ -z "$project" ]]; then
    echo "Usage: agent-configs [-f|--force] <project-name>"
    echo "Available projects:"
    find "$configs_dir" -mindepth 1 -maxdepth 1 -type d -not -name '.*' | xargs -I{} basename {} | sort | sed 's/^/  /'
    return 1
  fi

  if [[ ! -d "$source_dir" ]]; then
    echo "Error: project '$project' not found in $configs_dir"
    echo "Available projects:"
    find "$configs_dir" -mindepth 1 -maxdepth 1 -type d -not -name '.*' | xargs -I{} basename {} | sort | sed 's/^/  /'
    return 1
  fi

  local linked=0
  local skipped=0

  while IFS= read -r -d '' subdir; do
    local name="$(basename "$subdir")"
    local target="$PWD/$name"

    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$subdir" ]]; then
      echo "  skip  $name  (symlink already points to correct target)"
      (( skipped++ ))
    elif [[ -L "$target" ]] || [[ -e "$target" ]]; then
      if (( force )); then
        rm -rf "$target"
        ln -s "$subdir" "$target"
        echo "  replace  $name -> $subdir"
        (( linked++ ))
      else
        echo "  skip  $name  (already exists — use -f to replace)"
        (( skipped++ ))
      fi
    else
      ln -s "$subdir" "$target"
      echo "  link  $name -> $subdir"
      (( linked++ ))
    fi
  done < <(find "$source_dir" -mindepth 1 -maxdepth 1 -print0 | sort -z)

  echo ""
  echo "Done: $linked linked, $skipped skipped (project: $project)"
}
