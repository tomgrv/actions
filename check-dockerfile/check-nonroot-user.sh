#!/bin/sh

# Check that container runs as non-root user

DOCKERFILE="${1:-.}/Dockerfile"

if [ ! -f "$DOCKERFILE" ]; then
  exit 1
fi

# Check if there's a USER statement
if ! grep -q "^USER" "$DOCKERFILE"; then
  echo "$DOCKERFILE: no USER statement found. Add 'USER app' or similar non-root user for security."
  exit 1
fi

# Check if it's running as root
if grep -q "^USER root" "$DOCKERFILE"; then
  echo "$DOCKERFILE: container runs as root. Change to non-root user (e.g., 'USER app')."
  exit 1
fi

exit 0
