#!/bin/sh
# Scan immediate subdirectories of SCAN_PATH for package.json manifests and emit a JSON
# matrix of packages that are not private and not yet published at their current version.
#
# Requires: node, npm, jq
#
# Output format (stdout):
#   packages=[{"name":"…","version":"…","path":"…"}, …]

set -eu

SCAN_PATH="${SCAN_PATH:-src}"

packages='[]'

for dir in "$SCAN_PATH"/*/; do
  dir="${dir%/}"
  [ -f "$dir/package.json" ] || continue

  name=$(node -p "require('./$dir/package.json').name")
  version=$(node -p "require('./$dir/package.json').version")
  private=$(node -p "require('./$dir/package.json').private || false")

  if [ "$private" = "true" ]; then
    echo "Skipping $name (private)" >&2
    continue
  fi

  if npm view "$name@$version" version >/dev/null 2>&1; then
    echo "Skipping $name@$version (already published)" >&2
    continue
  fi

  echo "Will publish $name@$version" >&2
  packages=$(echo "$packages" | jq --arg name "$name" --arg version "$version" --arg path "$dir" '. + [{name: $name, version: $version, path: $path}]')
done

printf 'packages=%s\n' "$(echo "$packages" | jq -c .)"
