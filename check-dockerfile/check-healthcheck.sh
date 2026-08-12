#!/bin/sh

# Check that HEALTHCHECK is defined for orchestrator monitoring

DOCKERFILE="${1:-.}/Dockerfile"

if [ ! -f "$DOCKERFILE" ]; then
  exit 1
fi

if ! grep -q "^HEALTHCHECK" "$DOCKERFILE"; then
  echo "$DOCKERFILE: no HEALTHCHECK defined. Add HEALTHCHECK so orchestrators can detect stuck processes."
  exit 1
fi

exit 0
