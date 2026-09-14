# @format

# Tests setup-node/action.yml: shared Node setup and dependency-install guards.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  ACTION_FILE="${REPO_ROOT}/setup-node/action.yml"
}

@test "declares a composite action" {
  run grep -c '^  using: composite$' "$ACTION_FILE"
  [ "$status" -eq 0 ]
  [ "$output" -eq 1 ]
}

@test "skips redundant setup once TOMGRV_NODE_SETUP is set" {
  run grep -c "^      if: env.TOMGRV_NODE_SETUP != 'true'$" "$ACTION_FILE"
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]
}

@test "guards npm ci behind bare=false and a lock file" {
  run grep -F "if: \${{ env.TOMGRV_NODE_SETUP != 'true' && inputs.bare != 'true' && steps.git-bare.outputs.bare != 'true' && hashFiles('package-lock.json') }}" "$ACTION_FILE"
  [ "$status" -eq 0 ]
}

@test "marks the Node toolchain as ready for later steps" {
  run grep -F 'run: echo "TOMGRV_NODE_SETUP=true" >> "$GITHUB_ENV"' "$ACTION_FILE"
  [ "$status" -eq 0 ]
}
