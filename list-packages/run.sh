#!/bin/sh
# Discover packages via Composer and workspace package manifests, then emit a JSON array
# suitable for use as a GitHub Actions matrix value.
#
# Requires: jq, npm, curl
#
# Each package is checked against every registry configured for its ecosystem (see
# ecosystem_registries below), so a package can carry more than one registry entry.
#
# FILTER, when set, is a jq `select()` boolean expression evaluated against each
# final package object (e.g. `.private == false`, `.registry.npmjs.published == false`).
# Only packages for which it evaluates truthy are kept. Unset/empty keeps all packages.
#
# Output format (stdout):
#   packages=[{"org":"…","name":"…","path":"…","repository":"…","private":false,"registry":{"npmjs":{"published":true,"url":"https://registry.npmjs.org","type":"node"}, …}}, …]

set -eu

composer_packages='[]'
node_packages='[]'

WORKDIR="${WORKDIR:-$(pwd)}"
FILTER="${FILTER:-}"

if command -v composer >/dev/null 2>&1; then

    zz_log i "Discovering Composer packages..."

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
                  package_name:    $package.name,
                  package_version: ($package.version // "" | ltrimstr("v")),
                  ecosystem:       "php",
                  private:         false
                }
            ]')

    zz_log i "Discovered $(echo "$composer_packages" | jq 'length') Composer packages."

else
    # Missing binary is a setup concern, not a finding: plain log only.
    zz_log i "Composer not found, skipping Composer package discovery."
fi

if [ -f "$WORKDIR/package.json" ]; then

    zz_log i "Discovering package workspace packages in <$WORKDIR>..."

    node_packages=$(jq -r '.workspaces[]?' "$WORKDIR/package.json" \
        | while IFS= read -r workspace_pattern; do
            for package_dir in "$WORKDIR"/$workspace_pattern; do
                [ -d "$package_dir" ] || continue

                package_manifest="$package_dir/package.json"
                [ -f "$package_manifest" ] || continue

                location=${package_dir#"$WORKDIR"/}

                node_package=$(jq -c --arg path "$package_dir" --arg location "$location" '
                    .name as $package_name
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
                        package_name:    $package_name,
                        package_version: (.version // ""),
                        ecosystem:       "node",
                        private:         (.private // false)
                    }
                ' "$package_manifest")

                zz_log i "Discovered package: $(echo "$node_package" | jq -r '.package_name + "@" + .package_version')"
                echo "$node_package"
            done
        done | jq -cs '.')
        
else
    # Functional: absence of a file to analyze in the target repo is a notice.
    echo "::notice::Root package.json not found, skipping workspace package discovery." >&2
fi

zz_log i "Combining and normalizing package data..."

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
        | unique_by([.package_name, .ecosystem])
    ')

zz_log i "Checking package registries publication status..."

# Registries checked per ecosystem. Add more names here (space-separated) to check a
# package against several registries, and a matching check_<name> function below.
ecosystem_registries() {
    case "$1" in
        node) echo "npmjs" ;;
        php) echo "packagist" ;;
        *) echo "" ;;
    esac
}

check_npmjs() {
    name="$1"
    version="$2"
    published=false
    if [ -n "$version" ] && npm view "${name}@${version}" version >/dev/null 2>&1; then
        published=true
    fi
    jq -cn --argjson published "$published" --arg url "https://registry.npmjs.org" \
        '{published: $published, url: $url}'
}

check_packagist() {
    name="$1"
    version="$2"
    published=false
    if [ -n "$version" ] \
        && curl -fsS "https://repo.packagist.org/p2/${name}.json" 2>/dev/null \
            | jq -e --arg name "$name" --arg version "$version" '.packages[$name][]? | select(.version == $version or (.version | ltrimstr("v")) == $version)' >/dev/null 2>&1; then
        published=true
    fi
    jq -cn --argjson published "$published" --arg url "https://packagist.org" \
        '{published: $published, url: $url}'
}

count=$(echo "$packages" | jq 'length')
i=0
result='[]'
while [ "$i" -lt "$count" ]; do
    package=$(echo "$packages" | jq -c ".[$i]")
    package_name=$(echo "$package" | jq -r '.package_name')
    package_version=$(echo "$package" | jq -r '.package_version')
    ecosystem=$(echo "$package" | jq -r '.ecosystem')

    registry='{}'
    for registry_name in $(ecosystem_registries "$ecosystem"); do
        status=$(check_"$registry_name" "$package_name" "$package_version")
        registry=$(echo "$registry" | jq -c \
            --argjson status "$status" \
            --arg name "$registry_name" \
            --arg type "$ecosystem" \
            '. + {($name): ($status + {type: $type})}')
    done

    result=$(echo "$result" | jq -c \
        --argjson package "$package" \
        --argjson registry "$registry" \
        '. + [($package | del(.package_name, .package_version, .ecosystem)) + {registry: $registry}]')

    i=$((i + 1))
done

if [ -n "$FILTER" ]; then
    zz_log i "Applying filter: select($FILTER)"
    result=$(echo "$result" | jq -c "[.[] | select($FILTER)]")
fi

printf 'packages=%s\n' "$result"
