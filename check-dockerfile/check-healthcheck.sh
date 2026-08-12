#!/bin/sh

# Check that HEALTHCHECK is defined for orchestrator monitoring

DOCKERFILE="${1:-.}/Dockerfile"

if [ ! -f "$DOCKERFILE" ]; then
  exit 1
fi

if ! grep -q "^HEALTHCHECK" "$DOCKERFILE"; then
  # Report at end of file
  lastline=$(wc -l < "$DOCKERFILE")
  echo "$DOCKERFILE:$lastline: no HEALTHCHECK defined. Add HEALTHCHECK so orchestrators can detect stuck processes."
  exit 1
fi

exit 0
