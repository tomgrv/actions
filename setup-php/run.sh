#!/usr/bin/sh

set -e

extensions=''

if [ -f composer.lock ]; then
  extensions=$(jq -r '[
    ((.platform // {}) | keys[]?),
    ((.["platform-dev"] // {}) | keys[]?),
    ((.packages // [])[]? | (.require // {} | keys[]?)),
    ((.["packages-dev"] // [])[]? | (.require // {} | keys[]?))
  ]
  | map(select(startswith("ext-")) | .[4:])
  | unique
  | join(",")' composer.lock)
elif [ -f composer.json ]; then
  extensions=$(jq -r '.require | to_entries[] | select(.key | startswith("ext-")) | .key[4:]' composer.json | paste -sd "," -)
fi

printf 'extensions=%s\n' "${extensions}"
