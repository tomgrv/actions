#!/bin/sh

# Check that .dockerignore exists to prevent leaking secrets, git history, node_modules

CONTEXT_DIR="${1:-.}"

if [ ! -f "$CONTEXT_DIR/.dockerignore" ]; then
  echo "$CONTEXT_DIR/.dockerignore: file not found. Add .dockerignore to exclude .git, node_modules, secrets."
  exit 1
fi

exit 0
