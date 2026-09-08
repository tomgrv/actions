# @format

# Tests clean-branches/run.sh: Delete branches linked to closed PRs, skipping
# protected branches, forked branches, and branches with an open PR.

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/run.sh"
  STUB_DIR="$(mktemp -d)"
  PATH="${STUB_DIR}:${PATH}"

  cat > "${STUB_DIR}/zz_log" <<'EOF'
#!/usr/bin/sh
level="$1"
shift
echo "[$level] $*" >&2
EOF
  chmod +x "${STUB_DIR}/zz_log"
}

teardown() {
  rm -rf "${STUB_DIR}"
}

stub_gh() {
  # $1: closed PR list JSON output
  # $2: open PR list JSON output
  # $3: extra case statement body for `gh api`
  cat > "${STUB_DIR}/gh" <<EOF
#!/usr/bin/sh
if [ "\$1" = "pr" ] && [ "\$2" = "list" ]; then
  case "\$*" in
    *"--state closed"*) cat <<'JSON'
$1
JSON
      ;;
    *"--state open"*) cat <<'JSON'
$2
JSON
      ;;
  esac
  exit 0
fi
if [ "\$1" = "api" ]; then
  shift
  echo "gh api \$*" >> "${STUB_DIR}/api_calls.log"
  $3
  exit 0
fi
exit 1
EOF
  chmod +x "${STUB_DIR}/gh"
}

@test "deletes a branch from a merged, closed PR" {
  stub_gh \
    'feature/done	true' \
    '' \
    'exit 0'
  run env REPO="owner/repo" sh "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "deleted-branches<<EOF"
  echo "$output" | grep -q "feature/done"
  echo "$output" | grep -q "count=1"
}

@test "skips a protected branch" {
  stub_gh \
    'develop	true' \
    '' \
    'exit 0'
  run env REPO="owner/repo" PROTECTED_BRANCHES="main,develop" sh "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "count=0"
}

@test "skips a branch still referenced by an open PR" {
  stub_gh \
    'feature/reopened	false' \
    'feature/reopened' \
    'exit 0'
  run env REPO="owner/repo" sh "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "count=0"
}

@test "merged-only skips a closed but unmerged PR branch" {
  stub_gh \
    'feature/abandoned	false' \
    '' \
    'exit 0'
  run env REPO="owner/repo" MERGED_ONLY="true" sh "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "count=0"
}

@test "merged-only deletes a merged PR branch" {
  stub_gh \
    'feature/shipped	true' \
    '' \
    'exit 0'
  run env REPO="owner/repo" MERGED_ONLY="true" sh "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "feature/shipped"
  echo "$output" | grep -q "count=1"
}
