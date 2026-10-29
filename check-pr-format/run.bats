# @format

# Tests the GitLab branch of check-pr-format/run.sh: the merge request is read
# and edited through the REST API (curl), not the gh CLI. The toolchain
# (devmoji, commitlint) is stubbed, as it needs network and a package.json.

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/run.sh"
  BIN="$(mktemp -d)"
  CALLS="${BIN}/calls"
  # npm, zz-log and zz-npx stubs; by default devmoji leaves the title as is.
  printf '#!/bin/sh\nexit 0\n' >"${BIN}/npm"
  printf '#!/bin/sh\nshift; echo "$*"\n' >"${BIN}/zz-log"
  printf '#!/bin/sh\nif [ "$1" = devmoji ]; then echo "feat: fixed"; else cat >/dev/null; fi\n' >"${BIN}/zz-npx"
  printf '#!/bin/sh\necho "$@" >>"%s"\necho "{\\"title\\":\\"feat: fixed\\"}"\n' "$CALLS" >"${BIN}/curl"
  chmod +x "${BIN}"/*
}

teardown() {
  rm -rf "$BIN"
}

run_gitlab() {
  (
    cd "$BIN"
    export PATH="${BIN}:${PATH}" GITLAB_CI=true CI_API_V4_URL=https://gitlab.test/api/v4 CI_PROJECT_ID=7
    export REPO=g/p HEAD_REPO_FULL_NAME=g/p PR_NUMBER=3 PR_TITLE="feat: fixed" FIX="${1:-false}" GITLAB_TOKEN="${2:-}"
    sh "$SCRIPT"
  )
}

@test "gitlab: a title already formatted passes without calling the API" {
  run run_gitlab false tok
  [ "$status" -eq 0 ]
  [ ! -f "$CALLS" ]
}

# devmoji now rewrites the title, so the fix path is taken.
needs_fix() {
  printf '#!/bin/sh\nif [ "$1" = devmoji ]; then echo "feat: ✨ fixed"; else cat >/dev/null; fi\n' >"${BIN}/zz-npx"
}

@test "gitlab: fix updates the merge request title with the project token" {
  needs_fix
  run run_gitlab true tok
  [ "$status" -eq 0 ]
  grep -q 'PRIVATE-TOKEN: tok' "$CALLS"
  grep -q -- '--request PUT' "$CALLS"
  grep -q 'merge_requests/3' "$CALLS"
}

@test "gitlab: fix without a token fails instead of editing" {
  needs_fix
  run run_gitlab true ""
  [ "$status" -eq 1 ]
  [ ! -f "$CALLS" ]
}
