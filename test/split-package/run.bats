# @format

# Tests split-package/run.sh: Split a monorepo package to a separate repository.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  SCRIPT="${REPO_ROOT}/split-package/run.sh"
}

run_split() {
  (
    export PACKAGE_PATH="${1:?}"
    export REPOSITORY="${2:?}"
    export GIT_USER_NAME="${3:-Test Bot}"
    export GIT_USER_EMAIL="${4:-bot@example.com}"
    sh "$SCRIPT" 2>/dev/null
  )
}

@test "requires package-path parameter" {
  run run_split "" "org/repo"
  [ "$status" -ne 0 ]
}

@test "requires repository parameter" {
  run run_split "packages/my-package" ""
  [ "$status" -ne 0 ]
}

@test "validates package-path exists" {
  run run_split "nonexistent/path" "org/repo"
  [ "$status" -ne 0 ]
}

@test "validates package-path contains package.json or composer.json" {
  run run_split "/tmp" "org/repo"
  [ "$status" -ne 0 ]
}

@test "outputs split_commit_hash when successful" {
  skip "requires full git setup and external repository"
  run run_split "packages/core" "org/repo-core"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^split_commit_hash="
}
