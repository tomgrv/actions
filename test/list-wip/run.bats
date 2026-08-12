# @format

# Tests list-wip/run.sh: List files changed on current branch relative to base ref.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  SCRIPT="${REPO_ROOT}/list-wip/run.sh"
  TEST_DIR="$(mktemp -d)"
  REMOTE_DIR="$(mktemp -d)"

  # Setup remote repo
  git init -q --bare "$REMOTE_DIR"

  # Setup local repo
  cd "$TEST_DIR"
  git init -q
  git remote add origin "$REMOTE_DIR"
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create base branch (main)
  mkdir -p src app
  echo "<?php" > src/file.php
  echo "<?php" > app/config.php
  echo "plain" > readme.txt
  git add .
  git commit -q -m "Initial commit"
  git push -q -u origin main

  # Create feature branch
  git checkout -q -b feature/new-feature
  echo "<?php" > src/feature.php
  git add src/feature.php
  git commit -q -m "Add feature file"
}

teardown() {
  rm -rf "$TEST_DIR" "$REMOTE_DIR"
}

run_wip() {
  (
    cd "$TEST_DIR"
    export GITHUB_WORKSPACE="$TEST_DIR"
    export LIST_PATHS="${1:-.}"
    export LIST_EXTENSIONS="${2:-php}"
    export LIST_BASE_REF="${3:-main}"
    export GITHUB_BASE_REF="${3:-main}"
    sh "$SCRIPT" 2>/dev/null
  )
}

@test "lists files changed on feature branch compared to main" {
  run run_wip
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^count=1$"
  echo "$output" | grep -q "^has-files=true$"
  echo "$output" | grep -q "src/feature.php"
}

@test "excludes base branch files from list" {
  run run_wip
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "src/feature.php"
  echo "$output" | grep -q "src/file.php" && false || true
}

@test "path filter limits to specific directories" {
  echo "<?php" > "$TEST_DIR/app/new.php"
  git -C "$TEST_DIR" add app/new.php
  git -C "$TEST_DIR" commit -q -m "Add app file"

  run run_wip "src"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^count=1$"
  echo "$output" | grep -q "src/feature.php"
  echo "$output" | grep -q "app/new.php" && false || true
}

@test "extension filter limits to specific file types" {
  echo "plain text" > "$TEST_DIR/readme.md"
  git -C "$TEST_DIR" add readme.md
  git -C "$TEST_DIR" commit -q -m "Add markdown"

  run run_wip "." "php"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "src/feature.php"
  echo "$output" | grep -q "readme.md" && false || true
}

@test "missing base-ref returns empty list" {
  export LIST_BASE_REF=""
  export GITHUB_BASE_REF=""
  run run_wip "." "php" ""
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "^count=0$"
  echo "$output" | grep -q "^has-files=false$"
}

@test "multiple changed files are all included" {
  echo "<?php" > "$TEST_DIR/src/another.php"
  git -C "$TEST_DIR" add src/another.php
  git -C "$TEST_DIR" commit -q -m "Add another file"

  run run_wip
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^count=2$"
  echo "$output" | grep -q "src/feature.php"
  echo "$output" | grep -q "src/another.php"
}

@test "multiple extensions filter correctly" {
  echo "<?php" > "$TEST_DIR/app/new.php"
  echo "text" > "$TEST_DIR/docs.md"
  git -C "$TEST_DIR" add app/new.php docs.md
  git -C "$TEST_DIR" commit -q -m "Add files"

  run run_wip "." "php,md"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^count=3$"
  echo "$output" | grep -q "src/feature.php"
  echo "$output" | grep -q "app/new.php"
  echo "$output" | grep -q "docs.md"
}

@test "deleted files are included in comparison" {
  git -C "$TEST_DIR" rm src/file.php
  git -C "$TEST_DIR" commit -q -m "Delete file"

  run run_wip "src"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "src/file.php"
  echo "$output" | grep -q "src/feature.php"
}
