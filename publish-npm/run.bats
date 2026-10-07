# @format

# Tests publish-npm/run.sh: authentication is left to `npm publish` (OIDC trusted publishing).

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/publish-npm/run.sh"
  STUB_BIN="$(mktemp -d)"
  PKG="$(mktemp -d)"
  CALLS_FILE="$(mktemp)"
  GITHUB_OUTPUT="$(mktemp)"
  export CALLS_FILE GITHUB_OUTPUT
  unset GITHUB_WORKSPACE ACTIONS_ID_TOKEN_REQUEST_URL
  export PATH="${STUB_BIN}:${PATH}"
  export PACKAGE_PATH="${PKG}"
  printf '{"name":"@scope/pkg","version":"1.2.3"}\n' > "${PKG}/package.json"

  # zz-log stub: print level and message
  printf '#!/bin/sh\nshift\necho "$*" >&2\n' > "${STUB_BIN}/zz-log"
  # npm stub: record the call
  printf '#!/bin/sh\necho "npm $*" >> "%s"\n' "${CALLS_FILE}" > "${STUB_BIN}/npm"
  chmod +x "${STUB_BIN}/zz-log" "${STUB_BIN}/npm"
}

teardown() {
  rm -rf "${STUB_BIN}" "${PKG}" "${CALLS_FILE}" "${GITHUB_OUTPUT}"
}

@test "fails without OIDC when not a dry run" {
  run sh "${SCRIPT}"
  [ "$status" -eq 1 ]
  [[ "$output" == *"id-token: write"* ]]
  [ ! -s "${CALLS_FILE}" ]
}

@test "publishes with npm and writes no auth token when OIDC is available" {
  export ACTIONS_ID_TOKEN_REQUEST_URL="https://example.invalid/token"
  run sh "${SCRIPT}"
  [ "$status" -eq 0 ]
  grep -q 'npm publish --registry https://registry.npmjs.org/ --provenance' "${CALLS_FILE}"
  [ ! -e "${PKG}/.npmrc" ]
  grep -q 'version=1.2.3' "${GITHUB_OUTPUT}"
}

@test "dry run does not need OIDC and passes --dry-run" {
  export DRY_RUN=true
  run sh "${SCRIPT}"
  [ "$status" -eq 0 ]
  grep -q -- '--dry-run' "${CALLS_FILE}"
}

@test "non-default tag is forwarded" {
  export ACTIONS_ID_TOKEN_REQUEST_URL="https://example.invalid/token"
  export DIST_TAG=next
  run sh "${SCRIPT}"
  [ "$status" -eq 0 ]
  grep -q -- '--tag next' "${CALLS_FILE}"
}
