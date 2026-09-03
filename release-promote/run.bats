# @format

# Tests release-promote/run.sh: install release scripts, run beta->prod.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/release-promote/run.sh"
  STUB_BIN="$(mktemp -d)"
  export PATH="${STUB_BIN}:${PATH}"
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

@test "requires SCRIPTS_REF" {
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
}

@test "skips the network bootstrap when zz_use is already on PATH" {
  stub zz_use 0
  stub git-release-beta 0
  stub git-release-prod 0
  stub curl 1 # would fail loudly if actually invoked
  export SCRIPTS_REF=v1
  export DRY_RUN=true
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "dry-run stops before beta/prod run" {
  stub zz_use 0
  stub git-release-beta 1 # would fail if actually invoked
  stub git-release-prod 1
  export SCRIPTS_REF=v1
  export DRY_RUN=true
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run=true"* ]]
}

@test "runs beta then prod when not dry-run" {
  stub zz_use 0
  stub git-release-beta 0
  stub git-release-prod 0
  export SCRIPTS_REF=v1
  export DRY_RUN=false
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "errors clearly when prod push fails" {
  stub zz_use 0
  stub git-release-beta 0
  stub git-release-prod 1
  export SCRIPTS_REF=v1
  export DRY_RUN=false
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"protected-ref"* ]]
}

@test "errors clearly when beta fails, without running prod" {
  stub zz_use 0
  stub git-release-beta 1
  stub git-release-prod 1
  export SCRIPTS_REF=v1
  export DRY_RUN=false
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" != *"called: git-release-prod"* ]]
}
