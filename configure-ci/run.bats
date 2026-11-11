# @format

# Tests configure-ci/run.sh: forge detection, env export and the gh wrapper.

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/run.sh"
  STUB_DIR="$(mktemp -d)"
  PATH="${STUB_DIR}:${PATH}"
  export GITHUB_ENV="${STUB_DIR}/env" GITHUB_PATH="${STUB_DIR}/path" RUNNER_TEMP="${STUB_DIR}"
  : >"${GITHUB_ENV}" && : >"${GITHUB_PATH}"
  # curl stub: the Forgejo version probe succeeds only when PROBE_OK=1; anything else is a repo.
  cat >"${STUB_DIR}/curl" <<'EOF'
#!/bin/sh
for a; do url=$a; done
case "$url" in
*/api/forgejo/v1/version) [ "${PROBE_OK:-0}" = 1 ] && echo '{"version":"1"}' || exit 22 ;;
*) echo '{"full_name":"o/r","default_branch":"develop"}' ;;
esac
EOF
  chmod +x "${STUB_DIR}/curl"
}

teardown() { rm -rf "${STUB_DIR}"; }

@test "github: outputs github and leaves PATH alone" {
  run env GITHUB_SERVER_URL=https://github.com GITHUB_API_URL=https://api.github.com sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"forge=github"* ]]
  [[ "$output" == *"server-domain=github.com"* ]]
  [ ! -s "${GITHUB_PATH}" ]
  grep -q '^FORGE=github$' "${GITHUB_ENV}"
}

@test "forgejo: detected by the version probe, gh wrapper installed" {
  run env PROBE_OK=1 GITHUB_SERVER_URL=http://f GITHUB_API_URL=http://f/api/v1 sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"forge=forgejo"* ]]
  grep -q '^FORGE_FLAVOR=forgejo$' "${GITHUB_ENV}"
  grep -q '^FORGE_DOMAIN=f$' "${GITHUB_ENV}"
  bin="$(cat "${GITHUB_PATH}")"
  run env GITHUB_API_URL=http://f/api/v1 GITHUB_TOKEN=t "${bin}/gh" repo view o/r --json defaultBranchRef --jq .defaultBranchRef.name
  [ "$output" = develop ]
}

@test "gitea: Gitea-family API without the Forgejo endpoint" {
  run env PROBE_OK=0 GITHUB_SERVER_URL=http://g:3000/ GITHUB_API_URL=http://g/api/v1 sh "$SCRIPT"
  [[ "$output" == *"forge=gitea"* ]]
  [[ "$output" == *"server-domain=g:3000"* ]]
  grep -q '^FORGE=forgejo$' "${GITHUB_ENV}"
  grep -q '^FORGE_FLAVOR=gitea$' "${GITHUB_ENV}"
}
