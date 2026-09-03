# @format

# Tests release-promote/run.sh: run beta->prod, assuming setup-scripts and
# config-bot already ran (that's action.yml's job, not run.sh's -- see
# setup-scripts/run.bats for the bootstrap/install coverage).

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/release-promote/run.sh"
  STUB_BIN="$(mktemp -d)"
  export PATH="${STUB_BIN}:${PATH}"
  unset DRY_RUN
}

teardown() {
  rm -rf "${STUB_BIN}"
}

stub() {
  # stub <name> <exit-code>
  cat >"${STUB_BIN}/$1" <<STUB
#!/bin/sh
echo "called: $1 \$*" >&2
exit ${2:-0}
STUB
  chmod +x "${STUB_BIN}/$1"
}

@test "errors when git-release-beta isn't on PATH" {
  stub git-release-prod 0
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"git-release-beta not on PATH"* ]]
}

@test "errors when git-release-prod isn't on PATH" {
  stub git-release-beta 0
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"git-release-prod not on PATH"* ]]
}

@test "dry-run stops before beta/prod run" {
  stub git-release-beta 1 # would fail if actually invoked
  stub git-release-prod 1
  export DRY_RUN=true
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run=true"* ]]
}

@test "runs beta then prod when not dry-run" {
  stub git-release-beta 0
  stub git-release-prod 0
  export DRY_RUN=false
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "errors clearly when prod push fails" {
  stub git-release-beta 0
  stub git-release-prod 1
  export DRY_RUN=false
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"protected-ref"* ]]
}

@test "errors clearly when beta fails, without running prod" {
  stub git-release-beta 1
  stub git-release-prod 1
  export DRY_RUN=false
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" != *"called: git-release-prod"* ]]
}
