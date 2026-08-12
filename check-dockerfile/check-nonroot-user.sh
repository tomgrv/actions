#!/bin/sh

# Check that container runs as non-root user

DOCKERFILE="${1:-.}/Dockerfile"

if [ ! -f "$DOCKERFILE" ]; then
  exit 1
fi

# Check if it's running as root
if grep -n "^USER root" "$DOCKERFILE" | while read -r line; do
  linenum=$(echo "$line" | cut -d: -f1)
  echo "$DOCKERFILE:$linenum: container runs as root. Change to non-root user (e.g., 'USER app')."
  exit 1
done; then
  exit 0
fi

# Check if there's a USER statement
if ! grep -q "^USER" "$DOCKERFILE"; then
  echo "$DOCKERFILE:1: no USER statement found. Add 'USER app' or similar non-root user for security."
  exit 1
fi

exit 0
