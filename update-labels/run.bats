# @format

# Tests the GitLab branch of update-labels/run.sh: labels are listed, created,
# updated and deleted through the REST API (curl).

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/run.sh"
  STUB_DIR="$(mktemp -d)"
  printf '#!/bin/sh\nshift; echo "$*" >&2\n' >"${STUB_DIR}/zz-log"
  # curl: records the call; a GET answers with $EXISTING (a GitLab labels JSON array)
  cat >"${STUB_DIR}/curl" <<EOF
#!/bin/sh
echo "\$*" >>"${STUB_DIR}/calls"
case "\$*" in
*"--request"*) exit 0 ;;
*) echo "\${EXISTING:-[]}" ;;
esac
EOF
  chmod +x "${STUB_DIR}"/*
  LABELS_FILE="${STUB_DIR}/labels.json"
  echo '[{"name":"10 must","color":"b60205","description":"Must"},{"name":"20 should","color":"fbca04","description":"Should"}]' >"$LABELS_FILE"
}

teardown() {
  rm -rf "$STUB_DIR"
}

run_gitlab() {
  (
    export PATH="${STUB_DIR}:${PATH}" GITLAB_CI=true CI_API_V4_URL=https://gitlab.test/api/v4 REPOSITORY=g/p GITLAB_TOKEN="${1-tok}" LABELS_FILE
    sh "$SCRIPT"
  )
}

@test "gitlab: creates the missing labels with a hash-prefixed color" {
  run run_gitlab
  [ "$status" -eq 0 ]
  grep -q -- '--request POST .*--data-urlencode name=10 must --data-urlencode color=#b60205' "${STUB_DIR}/calls"
  grep -q 'PRIVATE-TOKEN: tok' "${STUB_DIR}/calls"
}

@test "gitlab: deletes labels that are not wanted, keeps the matching ones" {
  export EXISTING='[{"name":"stale","color":"#ffffff","description":""},{"name":"10 must","color":"#b60205","description":"Must"}]'
  run run_gitlab
  [ "$status" -eq 0 ]
  grep -q -- '--request DELETE .*/labels/stale' "${STUB_DIR}/calls"
  ! grep -q -- '--request DELETE .*/labels/10' "${STUB_DIR}/calls"
  ! grep -q -- '--request POST .*name=10 must' "${STUB_DIR}/calls"
}

@test "gitlab: fails without a token" {
  run run_gitlab ""
  [ "$status" -eq 1 ]
}
