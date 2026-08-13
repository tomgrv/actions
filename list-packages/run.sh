#!/bin/sh
# Discover packages via Composer and workspace package manifests, then emit a JSON array
# suitable for use as a GitHub Actions matrix value.
#
# Requires: jq, npm
#
# Output format (stdout):
#   packages=[{"org":"…","name":"…","path":"…","repository":"…","registry":{"npmjs":{"published":true,"url":"https://registry.npmjs.org","type":"node"}}}, …]

set -eu

composer_packages='[]'
node_packages='[]'

WORKDIR="${WORKDIR:-$(pwd)}"

if command -v composer >/dev/null 2>&1; then

    echo "Discovering Composer packages..." >&2

    composer_packages=$(composer show --direct --path --format=json --working-dir="$WORKDIR" \
        | jq -c --arg pwd "$WORKDIR" \
            '[.installed[]
            | select((.path | startswith($pwd + "/vendor") | not) and (.source != null) and (.abandoned != true))
              | . as $package
              | ($package.source) as $source
              | {
                  org:        ($package.name | split("/") | .[0]),
                  name:       ($package.name | split("/") | .[1]),
                  path:       $package.path,
                  location:   ($package.path | ltrimstr($pwd + "/")),
                  repository_url: (
                      if ($source | type) == "object" then
                          ($source.url // $source.reference // "")
                      elif ($source | type) == "string" then
                          $source
                      else
                          ""
                      end ),
                  npm_name:   $package.name,
                  npm_version: ($package.version // "" | ltrimstr("v")),
                  npm_type:   "php"
                }
              | select(.repository_url != "" and (.repository_url | test("github\\.com")))
            ]')

else
    # Missing binary is a setup concern, not a finding: plain log only.
    echo "Composer not found, skipping Composer package discovery." >&2
fi

if [ -f "$WORKDIR/package.json" ]; then

    echo "Discovering package workspace packages..." >&2

    node_packages=$(jq -r '.workspaces[]?' "$WORKDIR/package.json" \
        | while IFS= read -r workspace_pattern; do
            for package_dir in "$WORKDIR"/$workspace_pattern; do
                [ -d "$package_dir" ] || continue

                package_manifest="$package_dir/package.json"
                [ -f "$package_manifest" ] || continue

                location=${package_dir#"$WORKDIR"/}

                jq -c --arg path "$package_dir" --arg location "$location" '
                    select(.private != true)
                    | .name as $package_name
                    | ($package_name | ltrimstr("@") | split("/")) as $parts
                    | {
                        org: $parts[0],
                        name: ($parts[1] // $parts[0]),
                        path: $path,
                        location: $location,
                        repository_url: (
                            if (.repository | type) == "object" then
                                (.repository.url // "")
                            elif (.repository | type) == "string" then
                                .repository
                            else
                                ""
                            end
                        ),
                        npm_name: $package_name,
                        npm_version: (.version // ""),
                        npm_type: "node"
                    }
                    | select(.repository_url != "")
                ' "$package_manifest"
            done
        done | jq -cs '.')
else
    # Functional: absence of a file to analyze in the target repo is a notice.
    echo "::notice::Root package.json not found, skipping workspace package discovery." >&2
fi

echo "Combining and normalizing package data..." >&2

packages=$(jq -cn \
    --argjson composer "$composer_packages" \
    --argjson node "$node_packages" '
        def normalize_repository:
            .
            | sub("^git@github\\.com:"; "https://github.com/")
            | sub("^ssh://git@github\\.com/"; "https://github.com/")
            | sub("\\.git$"; "")
            | sub("/$"; "");

        ($composer + $node)
        | map(.repository_url |= normalize_repository)
        | unique_by(.repository_url)
    ')

echo "Checking npmjs registry publication status..." >&2

npmjs_registry_url="https://registry.npmjs.org"
count=$(echo "$packages" | jq 'length')
i=0
result='[]'
while [ "$i" -lt "$count" ]; do
    package=$(echo "$packages" | jq -c ".[$i]")
    npm_name=$(echo "$package" | jq -r '.npm_name')
    npm_version=$(echo "$package" | jq -r '.npm_version')
    npm_type=$(echo "$package" | jq -r '.npm_type')

    published=false
    if [ -n "$npm_version" ] && npm view "${npm_name}@${npm_version}" version >/dev/null 2>&1; then
        published=true
    fi

    result=$(echo "$result" | jq \
        --argjson package "$package" \
        --argjson published "$published" \
        --arg url "$npmjs_registry_url" \
        --arg type "$npm_type" \
        '. + [($package | del(.npm_name, .npm_version, .npm_type)) + {registry: {npmjs: {published: $published, url: $url, type: $type}}}]')

    i=$((i + 1))
done

printf 'packages=%s\n' "$result"
