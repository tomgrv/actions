# @format

# Tests the GitLab branch of create-pr/run.sh: the merge request is found,
# created or updated through the REST API (curl), and the branch is pushed with
# the access token. git push/remote and curl are stubbed.

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/run.sh"
  BIN="$(mktemp -d)"
  REPO_DIR="$(mktemp -d)"
  CALLS="${BIN}/calls"
  REAL_GIT="$(command -v git)"
  printf '#!/bin/sh\nshift; echo "$*" >&2\n' >"${BIN}/zz-log"
  # git: real, except push and remote set-url which are only recorded
  printf '#!/bin/sh\ncase "$1 $2" in "push origin"|"remote set-url") echo "git $*" >>"%s" ;; *) exec %s "$@" ;; esac\n' "$CALLS" "$REAL_GIT" >"${BIN}/git"
  # curl: records the call, answers like the GitLab API; EXISTING_MR=1 lists an open MR
  cat >"${BIN}/curl" <<'STUB'
#!/bin/sh
echo "curl $*" >>"$CALLS"
case "$*" in
*"merge_requests?state=opened"*) [ -n "$EXISTING_MR" ] && echo '[{"iid":5}]' || echo '[]' ;;
*"--request POST"*) echo '{"iid":9}' ;;
*"merge_requests/"*"--request PUT"* | *"--request PUT"*) echo '{}' ;;
*"merge_requests/"*) echo '{"web_url":"https://gitlab.test/g/p/-/merge_requests/N"}' ;;
*) echo '{"default_branch":"main"}' ;;
esac
STUB
  chmod +x "${BIN}"/*
  "$REAL_GIT" -C "$REPO_DIR" init -q
  "$REAL_GIT" -C "$REPO_DIR" config user.email t@t
  "$REAL_GIT" -C "$REPO_DIR" config user.name t
  echo x >"${REPO_DIR}/f"
}

teardown() {
  rm -rf "$BIN" "$REPO_DIR"
}

run_gitlab() {
  (
    cd "$REPO_DIR"
    export PATH="${BIN}:${PATH}" CALLS GITLAB_CI=true CI_API_V4_URL=https://gitlab.test/api/v4 CI_SERVER_HOST=gitlab.test
    export REPOSITORY=g/p HEAD_BRANCH=chore/x GITLAB_TOKEN="${1-tok}" EXISTING_MR="${2:-}" PR_TITLE=t PR_BODY=b
    sh "$SCRIPT"
  )
}

@test "gitlab: creates a merge request and pushes with the access token" {
  run run_gitlab tok
  [ "$status" -eq 0 ]
  [[ "$output" == *"action=created"* ]]
  [[ "$output" == *"pr-number=9"* ]]
  grep -q 'remote set-url origin https://oauth2:tok@gitlab.test/g/p.git' "$CALLS"
  grep -q 'git push origin HEAD:chore/x' "$CALLS"
  grep -q -- '--request POST' "$CALLS"
}

@test "gitlab: updates the open merge request of the branch" {
  run run_gitlab tok 1
  [ "$status" -eq 0 ]
  [[ "$output" == *"action=updated"* ]]
  [[ "$output" == *"pr-number=5"* ]]
  grep -q 'merge_requests/5 --data-urlencode' "$CALLS"
}

@test "gitlab: reports no changes without calling the API for the merge request" {
  git -C "$REPO_DIR" add f && git -C "$REPO_DIR" commit -qm init
  run run_gitlab tok
  [ "$status" -eq 0 ]
  [[ "$output" == *"has-changes=false"* ]]
  ! grep -q merge_requests "$CALLS"
}

@test "gitlab: fails without a token" {
  run run_gitlab ""
  [ "$status" -eq 1 ]
}
