# @format

# Tests the GitLab branch of degit-package/run.sh: the default branch of the source
# project is read through the REST API (curl), and the clone uses the access token
# (the tokenized URL is redirected to a local repository).

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/run.sh"
  BIN="$(mktemp -d)"
  SRC="$(mktemp -d)"
  TARGET="$(mktemp -d)"
  printf '#!/bin/sh\nshift; echo "$*" >&2\n' >"${BIN}/zz-log"
  printf '#!/bin/sh\necho "$*" >>"%s/calls"\necho "{\\"default_branch\\":\\"trunk\\"}"\n' "$BIN" >"${BIN}/curl"
  printf '#!/bin/sh\nexit 0\n' >"${BIN}/tree"
  # rsync stub: copies the source tree (minus .git) onto the destination
  cat >"${BIN}/rsync" <<'STUB'
#!/bin/sh
for a; do dst=$src; src=$a; done
(cd "${dst%/}" && tar --exclude=.git -cf - .) | (cd "${src%/}" && tar -xf -)
STUB
  chmod +x "${BIN}"/*
  git -C "$SRC" init -q -b trunk
  git -C "$SRC" config user.email t@t
  git -C "$SRC" config user.name t
  echo x >"${SRC}/f"
  git -C "$SRC" add f && git -C "$SRC" commit -qm init
  export GIT_CONFIG_GLOBAL="${BIN}/gitconfig"
  git config --global url."${SRC}".insteadOf "https://gitlab.test/g/p.git"
  git -C "$TARGET" init -q
}

teardown() {
  rm -rf "$BIN" "$SRC" "$TARGET"
}

run_gitlab() {
  (
    cd "$TARGET"
    export PATH="${BIN}:${PATH}" GITLAB_CI=true CI_SERVER_URL=https://gitlab.test CI_API_V4_URL=https://gitlab.test/api/v4
    export SOURCE_ORG=g SOURCE_NAME=p TARGET_SUBDIR=pkg GITLAB_TOKEN="${1-tok}"
    sh "$SCRIPT"
  )
}

@test "gitlab: imports the default branch of the source project into the target subdirectory" {
  run run_gitlab tok
  [ "$status" -eq 0 ]
  [[ "$output" == *"has-changes=true"* ]]
  [[ "$output" == *"source-branch=trunk"* ]]
  [ -f "${TARGET}/pkg/f" ]
  grep -q 'PRIVATE-TOKEN: tok' "${BIN}/calls"
  grep -q 'projects/g%2Fp' "${BIN}/calls"
}

@test "gitlab: fails without a token" {
  run run_gitlab ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"GITLAB_TOKEN is required"* ]]
}
