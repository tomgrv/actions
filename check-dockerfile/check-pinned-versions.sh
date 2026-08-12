#!/bin/sh

# Check that base images use pinned versions (not 'latest')

DOCKERFILE="${1:-.}/Dockerfile"

if [ ! -f "$DOCKERFILE" ]; then
  exit 1
fi

if grep -n "FROM.*:latest" "$DOCKERFILE"; then
  echo "$DOCKERFILE: FROM statement uses 'latest' tag. Use pinned versions for reproducible builds."
  exit 1
fi

exit 0
