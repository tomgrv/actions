#!/bin/sh

# Check that Dockerfile uses multi-stage build pattern

DOCKERFILE="${1:-.}/Dockerfile"

if [ ! -f "$DOCKERFILE" ]; then
  exit 1
fi

from_count=$(grep -c "^FROM" "$DOCKERFILE" || true)

if [ "$from_count" -lt 2 ]; then
  # Report the first FROM line
  firstfrom=$(grep -n "^FROM" "$DOCKERFILE" | head -1 | cut -d: -f1)
  echo "$DOCKERFILE:$firstfrom: single-stage build detected. Consider using multi-stage to separate build tools from runtime."
  exit 1
fi

exit 0
