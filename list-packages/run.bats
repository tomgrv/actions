# @format

# Tests list-packages/run.sh: Discover Composer and npm workspace packages and
# emit a JSON matrix, including per-package registry publication status.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/list-packages/run.sh"
  TEST_DIR="$(mktemp -d)"
  STUB_BIN="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_DIR" "$STUB_BIN"
}

stub_npm() {
  # $1: file listing published "name@version" specs, one per line
  cat > "$STUB_BIN/npm" <<EOF
#!/bin/sh
if [ "\$1" = "view" ]; then
  if grep -qxF "\$2" "$1" 2>/dev/null; then
    echo "\${2##*@}"
    exit 0
  fi
  exit 1
fi
exit 1
EOF
  chmod +x "$STUB_BIN/npm"
}

stub_curl_packagist() {
  # $1: directory containing "<org>_<name>.json" packagist p2 fixtures
  fixtures_dir="$1"
  cat > "$STUB_BIN/curl" <<EOF
#!/bin/sh
for arg in "\$@"; do
  case "\$arg" in
    https://repo.packagist.org/p2/*)
      pkg="\${arg#https://repo.packagist.org/p2/}"
      pkg="\${pkg%.json}"
      fixture="$fixtures_dir/\$(echo "\$pkg" | tr '/' '_').json"
      if [ -f "\$fixture" ]; then
        cat "\$fixture"
        exit 0
      fi
      exit 22
      ;;
  esac
done
exit 22
EOF
  chmod +x "$STUB_BIN/curl"
}

stub_composer() {
  # $1: file containing the `composer show --format=json` output
  cat > "$STUB_BIN/composer" <<EOF
#!/bin/sh
cat "$1"
EOF
  chmod +x "$STUB_BIN/composer"
}

run_list() {
  (
    export WORKDIR="$TEST_DIR"
    export FILTER="${1:-}"
    # Curated PATH: stubs first, then just enough of the real toolchain (jq, npm,
    # coreutils) to run the script -- deliberately excludes /usr/local/bin so the
    # host's real `composer` binary never shadows a test that isn't stubbing it.
    export PATH="$STUB_BIN:/opt/node22/bin:/usr/bin:/bin"
    sh "$SCRIPT" 2>/dev/null
  )
}

packages_json() {
  echo "$output" | sed -n 's/^packages=//p'
}

@test "no package.json and no composer yields empty packages array" {
  run run_list
  [ "$status" -eq 0 ]
  [ "$(packages_json)" = "[]" ]
}

@test "node workspace package published on npmjs is marked published" {
  mkdir -p "$TEST_DIR/packages/foo"
  cat > "$TEST_DIR/package.json" <<'EOF'
{ "workspaces": ["packages/*"] }
EOF
  cat > "$TEST_DIR/packages/foo/package.json" <<'EOF'
{ "name": "foo", "version": "1.0.0", "repository": "https://github.com/org/foo" }
EOF

  echo "foo@1.0.0" > "$TEST_DIR/npm-published.txt"
  stub_npm "$TEST_DIR/npm-published.txt"

  run run_list
  [ "$status" -eq 0 ]
  published=$(packages_json | jq -r '.[0].registry.npmjs.published')
  url=$(packages_json | jq -r '.[0].registry.npmjs.url')
  type=$(packages_json | jq -r '.[0].registry.npmjs.type')
  [ "$published" = "true" ]
  [ "$url" = "https://registry.npmjs.org" ]
  [ "$type" = "node" ]
}

@test "node workspace package not yet published is marked unpublished" {
  mkdir -p "$TEST_DIR/packages/bar"
  cat > "$TEST_DIR/package.json" <<'EOF'
{ "workspaces": ["packages/*"] }
EOF
  cat > "$TEST_DIR/packages/bar/package.json" <<'EOF'
{ "name": "bar", "version": "9.9.9", "repository": "https://github.com/org/bar" }
EOF

  : > "$TEST_DIR/npm-published.txt"
  stub_npm "$TEST_DIR/npm-published.txt"

  run run_list
  [ "$status" -eq 0 ]
  published=$(packages_json | jq -r '.[0].registry.npmjs.published')
  [ "$published" = "false" ]
}

@test "private node workspace packages are included by default and flagged private:true" {
  mkdir -p "$TEST_DIR/packages/priv"
  cat > "$TEST_DIR/package.json" <<'EOF'
{ "workspaces": ["packages/*"] }
EOF
  cat > "$TEST_DIR/packages/priv/package.json" <<'EOF'
{ "name": "priv", "version": "1.0.0", "private": true, "repository": "https://github.com/org/priv" }
EOF

  stub_npm "$TEST_DIR/npm-published.txt"

  run run_list
  [ "$status" -eq 0 ]
  [ "$(packages_json | jq 'length')" = "1" ]
  [ "$(packages_json | jq -r '.[0].private')" = "true" ]
}

@test "public node workspace packages are flagged private:false" {
  mkdir -p "$TEST_DIR/packages/pub"
  cat > "$TEST_DIR/package.json" <<'EOF'
{ "workspaces": ["packages/*"] }
EOF
  cat > "$TEST_DIR/packages/pub/package.json" <<'EOF'
{ "name": "pub", "version": "1.0.0", "repository": "https://github.com/org/pub" }
EOF

  stub_npm "$TEST_DIR/npm-published.txt"

  run run_list
  [ "$status" -eq 0 ]
  [ "$(packages_json | jq -r '.[0].private')" = "false" ]
}

@test "filter='.private == false' keeps only public packages" {
  mkdir -p "$TEST_DIR/packages/priv" "$TEST_DIR/packages/pub"
  cat > "$TEST_DIR/package.json" <<'EOF'
{ "workspaces": ["packages/*"] }
EOF
  cat > "$TEST_DIR/packages/priv/package.json" <<'EOF'
{ "name": "priv", "version": "1.0.0", "private": true, "repository": "https://github.com/org/priv" }
EOF
  cat > "$TEST_DIR/packages/pub/package.json" <<'EOF'
{ "name": "pub", "version": "1.0.0", "repository": "https://github.com/org/pub" }
EOF

  stub_npm "$TEST_DIR/npm-published.txt"

  run run_list '.private == false'
  [ "$status" -eq 0 ]
  [ "$(packages_json | jq 'length')" = "1" ]
  [ "$(packages_json | jq -r '.[0].name')" = "pub" ]
}

@test "filter='.private == true' keeps only private packages" {
  mkdir -p "$TEST_DIR/packages/priv" "$TEST_DIR/packages/pub"
  cat > "$TEST_DIR/package.json" <<'EOF'
{ "workspaces": ["packages/*"] }
EOF
  cat > "$TEST_DIR/packages/priv/package.json" <<'EOF'
{ "name": "priv", "version": "1.0.0", "private": true, "repository": "https://github.com/org/priv" }
EOF
  cat > "$TEST_DIR/packages/pub/package.json" <<'EOF'
{ "name": "pub", "version": "1.0.0", "repository": "https://github.com/org/pub" }
EOF

  stub_npm "$TEST_DIR/npm-published.txt"

  run run_list '.private == true'
  [ "$status" -eq 0 ]
  [ "$(packages_json | jq 'length')" = "1" ]
  [ "$(packages_json | jq -r '.[0].name')" = "priv" ]
}

@test "unset filter keeps both public and private packages" {
  mkdir -p "$TEST_DIR/packages/priv" "$TEST_DIR/packages/pub"
  cat > "$TEST_DIR/package.json" <<'EOF'
{ "workspaces": ["packages/*"] }
EOF
  cat > "$TEST_DIR/packages/priv/package.json" <<'EOF'
{ "name": "priv", "version": "1.0.0", "private": true, "repository": "https://github.com/org/priv" }
EOF
  cat > "$TEST_DIR/packages/pub/package.json" <<'EOF'
{ "name": "pub", "version": "1.0.0", "repository": "https://github.com/org/pub" }
EOF

  stub_npm "$TEST_DIR/npm-published.txt"

  run run_list ""
  [ "$status" -eq 0 ]
  [ "$(packages_json | jq 'length')" = "2" ]
}

@test "filter can select on the nested registry structure" {
  mkdir -p "$TEST_DIR/packages/foo" "$TEST_DIR/packages/bar"
  cat > "$TEST_DIR/package.json" <<'EOF'
{ "workspaces": ["packages/*"] }
EOF
  cat > "$TEST_DIR/packages/foo/package.json" <<'EOF'
{ "name": "foo", "version": "1.0.0", "repository": "https://github.com/org/foo" }
EOF
  cat > "$TEST_DIR/packages/bar/package.json" <<'EOF'
{ "name": "bar", "version": "9.9.9", "repository": "https://github.com/org/bar" }
EOF

  echo "foo@1.0.0" > "$TEST_DIR/npm-published.txt"
  stub_npm "$TEST_DIR/npm-published.txt"

  run run_list '.registry.npmjs.published == false'
  [ "$status" -eq 0 ]
  [ "$(packages_json | jq 'length')" = "1" ]
  [ "$(packages_json | jq -r '.[0].name')" = "bar" ]
}

@test "composer package published on packagist is marked published and checked against packagist, not npmjs" {
  fixtures_dir="$TEST_DIR/packagist-fixtures"
  mkdir -p "$fixtures_dir"
  cat > "$fixtures_dir/acme_widgets.json" <<'EOF'
{ "packages": { "acme/widgets": [ { "version": "2.0.0" } ] } }
EOF
  stub_curl_packagist "$fixtures_dir"

  # Path-repository (monorepo-local) packages resolve outside vendor/, which is
  # what list-packages' vendor-exclusion filter expects for owned packages.
  mkdir -p "$TEST_DIR/packages/widgets"
  cat > "$TEST_DIR/composer-show.json" <<EOF
{
  "installed": [
    {
      "name": "acme/widgets",
      "version": "2.0.0",
      "path": "$TEST_DIR/packages/widgets",
      "source": { "url": "https://github.com/acme/widgets.git" },
      "abandoned": false
    }
  ]
}
EOF
  stub_composer "$TEST_DIR/composer-show.json"

  run run_list
  [ "$status" -eq 0 ]
  published=$(packages_json | jq -r '.[0].registry.packagist.published')
  url=$(packages_json | jq -r '.[0].registry.packagist.url')
  type=$(packages_json | jq -r '.[0].registry.packagist.type')
  has_npmjs=$(packages_json | jq -r '.[0].registry | has("npmjs")')
  [ "$published" = "true" ]
  [ "$url" = "https://packagist.org" ]
  [ "$type" = "php" ]
  [ "$has_npmjs" = "false" ]
}

@test "composer package not on packagist is marked unpublished" {
  fixtures_dir="$TEST_DIR/packagist-fixtures"
  mkdir -p "$fixtures_dir"
  stub_curl_packagist "$fixtures_dir"

  mkdir -p "$TEST_DIR/packages/gadgets"
  cat > "$TEST_DIR/composer-show.json" <<EOF
{
  "installed": [
    {
      "name": "acme/gadgets",
      "version": "1.0.0",
      "path": "$TEST_DIR/packages/gadgets",
      "source": { "url": "https://github.com/acme/gadgets.git" },
      "abandoned": false
    }
  ]
}
EOF
  stub_composer "$TEST_DIR/composer-show.json"

  run run_list
  [ "$status" -eq 0 ]
  published=$(packages_json | jq -r '.[0].registry.packagist.published')
  [ "$published" = "false" ]
}

@test "package published as both a php (Composer) and node (npm) artifact under the same repository gets both registry entries" {
  same_repository_url="https://github.com/acme/hybrid"

  # Composer side: monorepo-local path package (outside vendor/).
  mkdir -p "$TEST_DIR/packages/hybrid-php"
  cat > "$TEST_DIR/composer-show.json" <<EOF
{
  "installed": [
    {
      "name": "acme/hybrid",
      "version": "1.5.0",
      "path": "$TEST_DIR/packages/hybrid-php",
      "source": { "url": "${same_repository_url}.git" },
      "abandoned": false
    }
  ]
}
EOF
  stub_composer "$TEST_DIR/composer-show.json"

  fixtures_dir="$TEST_DIR/packagist-fixtures"
  mkdir -p "$fixtures_dir"
  cat > "$fixtures_dir/acme_hybrid.json" <<'EOF'
{ "packages": { "acme/hybrid": [ { "version": "1.5.0" } ] } }
EOF
  stub_curl_packagist "$fixtures_dir"

  # Node side: npm workspace package for the same repository.
  cat > "$TEST_DIR/package.json" <<'EOF'
{ "workspaces": ["packages/*"] }
EOF
  mkdir -p "$TEST_DIR/packages/hybrid-js"
  cat > "$TEST_DIR/packages/hybrid-js/package.json" <<EOF
{ "name": "hybrid", "version": "1.5.0", "repository": "${same_repository_url}" }
EOF

  echo "hybrid@1.5.0" > "$TEST_DIR/npm-published.txt"
  stub_npm "$TEST_DIR/npm-published.txt"

  run run_list
  [ "$status" -eq 0 ]

  count=$(packages_json | jq 'length')
  [ "$count" = "2" ]

  php_entry=$(packages_json | jq -c '.[] | select(.registry | has("packagist"))')
  node_entry=$(packages_json | jq -c '.[] | select(.registry | has("npmjs"))')

  [ -n "$php_entry" ]
  [ -n "$node_entry" ]

  [ "$(echo "$php_entry" | jq -r '.registry.packagist.published')" = "true" ]
  [ "$(echo "$php_entry" | jq -r '.registry | has("npmjs")')" = "false" ]

  [ "$(echo "$node_entry" | jq -r '.registry.npmjs.published')" = "true" ]
  [ "$(echo "$node_entry" | jq -r '.registry | has("packagist")')" = "false" ]
}
