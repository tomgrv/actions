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

@test "comments on each PR merged since the previous release" {
  cd "$(mktemp -d)"
  git init -q -b main . && git config user.email a@b && git config user.name n
  git commit -q --allow-empty -m one && git tag v1.0.0
  git update-ref refs/remotes/origin/main HEAD
  git commit -q --allow-empty -m "two (#7)" && git tag v1.1.0
  stub git-release-beta 0
  stub git-release-prod 0
  stub zz-log 0
  cat >"${STUB_BIN}/gh" <<'GH'
#!/bin/sh
case "$1" in
  api) echo 7 ;;
  pr) [ "$2" = view ] && echo 9 || echo "gh $*" >&2 ;;
  issue) echo "gh $*" >&2 ;;
esac
GH
  chmod +x "${STUB_BIN}/gh"
  export DRY_RUN=false GITHUB_REPOSITORY=o/r
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"pr comment 7 --repo o/r --body Released to main branch as v1.1.0"* ]]
  [[ "$output" == *"issue comment 9 --repo o/r --body Released to main branch as v1.1.0"* ]]
}

# GitLab: the release is pushed with the access token and the "Released" comments
# go to the merge requests (and the issues they close) through the REST API.
gitlab_repo() {
  REPO="$(mktemp -d)"
  git -C "$REPO" init -q -b main
  git -C "$REPO" config user.email t@t
  git -C "$REPO" config user.name t
  git -C "$REPO" commit -q --allow-empty -m one
  git -C "$REPO" tag v1.0.0
  git -C "$REPO" remote add origin https://gitlab.test/g/p.git
  git -C "$REPO" update-ref refs/remotes/origin/main HEAD
  # git-release-prod stub: ships one more commit as v1.1.0
  cat >"${STUB_BIN}/git-release-prod" <<STUB
#!/bin/sh
git commit -q --allow-empty -m two && git tag v1.1.0
STUB
  stub git-release-beta 0
  chmod +x "${STUB_BIN}/git-release-prod"
  cat >"${STUB_BIN}/curl" <<STUB
#!/bin/sh
echo "\$*" >>"${REPO}/calls"
case "\$*" in
*"/merge_requests"|*"merge_requests") echo '[{"iid":4,"state":"merged"}]' ;;
*"closes_issues"*) echo '[{"iid":8}]' ;;
esac
STUB
  chmod +x "${STUB_BIN}/curl"
  printf '#!/bin/sh\nshift; echo "$*" >&2\n' >"${STUB_BIN}/zz-log"
  chmod +x "${STUB_BIN}/zz-log"
}

run_gitlab() {
  (
    cd "$REPO"
    export GITLAB_CI=true CI_API_V4_URL=https://gitlab.test/api/v4 CI_PROJECT_ID=7 CI_PROJECT_PATH=g/p CI_SERVER_HOST=gitlab.test GITLAB_TOKEN="${1-tok}"
    sh "$SCRIPT"
  )
}

@test "gitlab: fails without a token" {
  gitlab_repo
  run run_gitlab ""
  [ "$status" -ne 0 ]
  [[ "$output" == *"GITLAB_TOKEN"* ]]
}

@test "gitlab: pushes with the access token and comments the released merge requests and issues" {
  gitlab_repo
  run run_gitlab
  [ "$status" -eq 0 ]
  [ "$(git -C "$REPO" remote get-url origin)" = "https://oauth2:tok@gitlab.test/g/p.git" ]
  grep -q -- '--request POST .*/merge_requests/4/notes --data-urlencode body=Released to main branch as v1.1.0' "${REPO}/calls"
  grep -q -- '--request POST .*/issues/8/notes --data-urlencode body=Released to main branch as v1.1.0' "${REPO}/calls"
}

@test "gitlab: dry-run does not touch the remote" {
  gitlab_repo
  DRY_RUN=true run run_gitlab
  [ "$status" -eq 0 ]
  [ "$(git -C "$REPO" remote get-url origin)" = "https://gitlab.test/g/p.git" ]
}
