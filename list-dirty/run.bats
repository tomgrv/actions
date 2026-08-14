# @format

# Tests list-dirty/run.sh: List files with uncommitted changes (staged, unstaged, untracked).

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/list-dirty/run.sh"
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  mkdir -p src app
  echo "<?php" > src/file.php
  echo "<?php" > app/config.php
  echo "plain" > readme.txt
  git add .
  git commit -q -m "Initial commit"
}

teardown() {
  rm -rf "$TEST_DIR"
}

run_dirty() {
  (
    cd "$TEST_DIR"
    export GITHUB_WORKSPACE="$TEST_DIR"
    export LIST_PATHS="${1:-.}"
    export LIST_EXTENSIONS="${2:-php}"
    sh "$SCRIPT" 2>/dev/null
  )
}

@test "no dirty files returns count 0" {
  run run_dirty
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^count=0$"
  echo "$output" | grep -q "^has-files=false$"
}

@test "unstaged php file is detected" {
  echo "modified" >> "$TEST_DIR/src/file.php"
  run run_dirty
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^count=1$"
  echo "$output" | grep -q "^has-files=true$"
  echo "$output" | grep -q "src/file.php"
}

@test "untracked php file is detected" {
  touch "$TEST_DIR/src/new.php"
  run run_dirty
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^count=1$"
  echo "$output" | grep -q "src/new.php"
}

@test "staged php file is detected" {
  echo "<?php" > "$TEST_DIR/new.php"
  git -C "$TEST_DIR" add new.php
  run run_dirty
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^count=1$"
  echo "$output" | grep -q "new.php"
}

@test "multiple dirty files are counted correctly" {
  echo "modified" >> "$TEST_DIR/src/file.php"
  touch "$TEST_DIR/app/new.php"
  echo "<?php" > "$TEST_DIR/other.php"
  git -C "$TEST_DIR" add other.php
  run run_dirty
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^count=3$"
  echo "$output" | grep -q "src/file.php"
  echo "$output" | grep -q "app/new.php"
  echo "$output" | grep -q "other.php"
}

@test "extension filter excludes non-php files" {
  echo "modified" >> "$TEST_DIR/readme.txt"
  echo "<?php" > "$TEST_DIR/new.php"
  run run_dirty
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^count=1$"
  echo "$output" | grep -q "new.php"
  echo "$output" | grep -q "readme.txt" && false || true
}

@test "path filter limits to specific directories" {
  echo "modified" >> "$TEST_DIR/src/file.php"
  echo "modified" >> "$TEST_DIR/app/config.php"
  run run_dirty "src"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^count=1$"
  echo "$output" | grep -q "src/file.php"
  echo "$output" | grep -q "app/config.php" && false || true
}

@test "multiple extensions can be specified" {
  echo "modified" >> "$TEST_DIR/src/file.php"
  echo "updated" >> "$TEST_DIR/readme.txt"
  run run_dirty "." "php,txt"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^count=2$"
  echo "$output" | grep -q "src/file.php"
  echo "$output" | grep -q "readme.txt"
}

@test "deleted php file is included" {
  rm "$TEST_DIR/src/file.php"
  run run_dirty
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "^count=1$"
  echo "$output" | grep -q "src/file.php"
}
