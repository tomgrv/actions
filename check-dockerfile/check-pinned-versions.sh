#!/bin/sh

# Check that base images use pinned versions (not 'latest')

DOCKERFILE="${1:-.}/Dockerfile"

if [ ! -f "$DOCKERFILE" ]; then
  exit 1
fi

# grep -n outputs "line:content", we need "file:line:message" for reviewdog
if grep -n "FROM.*:latest" "$DOCKERFILE" | while read -r line; do
  linenum=$(echo "$line" | cut -d: -f1)
  echo "$DOCKERFILE:$linenum: FROM statement uses 'latest' tag. Use pinned versions for reproducible builds."
  exit 1
done; then
  exit 0
fi

exit 1
