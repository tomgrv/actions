#!/usr/bin/sh

set -e

if [ -f composer.lock ]; then
  jq -r '[
    ((.platform // {}) | keys[]?),
    ((.["platform-dev"] // {}) | keys[]?),
    ((.packages // [])[]? | (.require // {} | keys[]?)),
    ((.["packages-dev"] // [])[]? | (.require // {} | keys[]?))
  ]
  | map(select(startswith("ext-")) | .[4:])
  | unique
  | join(",")' composer.lock
elif [ -f composer.json ]; then
  jq -r '.require | to_entries[] | select(.key | startswith("ext-")) | .key[4:]' composer.json | paste -sd "," -
else
  echo ""
fi
