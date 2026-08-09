#!/usr/bin/sh

# Extract the `ext-*` PHP extensions required by composer.lock (preferred) or
# composer.json, for use by shivammathur/setup-php.

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
