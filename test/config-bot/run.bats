# @format

# Tests config-bot/run.sh: Configure git bot identity.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  SCRIPT="${REPO_ROOT}/config-bot/run.sh"
  # Unset git config to start fresh
  git config --global --unset user.name 2>/dev/null || true
  git config --global --unset user.email 2>/dev/null || true
}

run_config() {
  (
    export BOT_NAME="${1:-}"
    export BOT_EMAIL="${2:-}"
    sh "$SCRIPT" 2>/dev/null
  )
}

@test "sets default bot name and email" {
  run run_config
  [ "$status" -eq 0 ]
  [ "$(git config --global user.name)" = "github-actions[bot]" ]
  [ "$(git config --global user.email)" = "341898282+github-actions[bot]@users.noreply.github.com" ]
}

@test "outputs default values" {
  run run_config
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "git_user_name=github-actions\[bot\]"
  echo "$output" | grep -q "git_user_email=341898282+github-actions\[bot\]@users.noreply.github.com"
}

@test "uses custom bot name when provided" {
  run run_config "custom-bot" "custom@example.com"
  [ "$status" -eq 0 ]
  [ "$(git config --global user.name)" = "custom-bot" ]
}

@test "uses custom bot email when provided" {
  run run_config "custom-bot" "custom@example.com"
  [ "$status" -eq 0 ]
  [ "$(git config --global user.email)" = "custom@example.com" ]
}

@test "outputs custom values" {
  run run_config "my-bot" "bot@company.com"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "git_user_name=my-bot"
  echo "$output" | grep -q "git_user_email=bot@company.com"
}

@test "returns exactly two output lines" {
  run run_config "bot" "bot@example.com"
  [ "$status" -eq 0 ]
  lines_count=$(echo "$output" | grep -c "git_user")
  [ "$lines_count" -eq 2 ]
}
