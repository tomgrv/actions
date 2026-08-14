# @format

# Tests detect-changes/run.sh: Detect uncommitted or untracked changes using git status.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/detect-changes/run.sh"
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  echo "initial" > file.txt
  git add file.txt
  git commit -q -m "Initial commit"
}

teardown() {
  rm -rf "$TEST_DIR"
}

run_detect() {
  (
    cd "$TEST_DIR"
    export WORKDIR="${1:-.}"
    export OPTIONS="${2:-}"
    export GITHUB_WORKSPACE="$TEST_DIR"
    sh "$SCRIPT"
  )
}

@test "no changes detected returns false" {
  run run_detect
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^has-changes=false$"
}

@test "uncommitted modification detected returns true" {
  echo "modified" > "$TEST_DIR/file.txt"
  run run_detect
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^has-changes=true$"
}

@test "untracked file detected returns true" {
  touch "$TEST_DIR/new-file.txt"
  run run_detect
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^has-changes=true$"
}

@test "deleted file detected returns true" {
  rm "$TEST_DIR/file.txt"
  run run_detect
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^has-changes=true$"
}

@test "subdirectory path filter respects path argument" {
  mkdir -p "$TEST_DIR/subdir"
  echo "content" > "$TEST_DIR/subdir/file.txt"
  git add "$TEST_DIR/subdir/file.txt"
  git commit -q -m "Add subdir file"
  touch "$TEST_DIR/other-file.txt"
  echo "change" > "$TEST_DIR/subdir/file.txt"

  run run_detect "subdir"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^has-changes=true$"

  # No changes in other-file, so detect against other path
  run run_detect "."
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^has-changes=true$"
}

@test "git status options are passed through" {
  echo "*.log" > "$TEST_DIR/.gitignore"
  git add "$TEST_DIR/.gitignore"
  git commit -q -m "Add gitignore"
  touch "$TEST_DIR/ignored.log"

  # Without --ignored, should not detect
  run run_detect "." ""
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^has-changes=false$"

  # With --ignored, should detect
  run run_detect "." "--ignored"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^has-changes=true$"
}

@test "nonexistent path returns false" {
  run run_detect "nonexistent"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^has-changes=false$"
}

@test "default workdir is dot when not set" {
  touch "$TEST_DIR/untracked.txt"
  run run_detect ""
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^has-changes=true$"
}
