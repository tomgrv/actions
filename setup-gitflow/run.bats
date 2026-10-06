# @format

# Tests setup-gitflow/run.sh: install git-flow if missing, then init it.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/setup-gitflow/run.sh"
  STUB_BIN="$(mktemp -d)"
  export PATH="${STUB_BIN}:${PATH}"
  CALLS_FILE="$(mktemp)"
  export CALLS_FILE
  unset GITFLOW_MASTER_BRANCH
  unset GITFLOW_DEVELOP_BRANCH
}

teardown() {
  rm -rf "${STUB_BIN}"
  rm -f "${CALLS_FILE}"
}

stub() {
  # stub <name> <exit-code>
  cat > "${STUB_BIN}/$1" << STUB
#!/bin/sh
echo "called: $1 \$*" >&2
exit ${2:-0}
STUB
  chmod +x "${STUB_BIN}/$1"
}

# git stub: "flow version" toggles via GITFLOW_INSTALLED marker file;
# "config"/"flow init" are recorded to CALLS_FILE and always succeed.
stub_git_dispatcher() {
  installed="$1" # "yes" or "no" -- whether `git flow version` succeeds up front
  cat > "${STUB_BIN}/git" << STUB
#!/bin/sh
echo "git \$*" >> "${CALLS_FILE}"
if [ "\$1" = "flow" ] && [ "\$2" = "version" ]; then
  if [ -f "${STUB_BIN}/.installed" ]; then
    exit 0
  fi
  [ "${installed}" = "yes" ] && exit 0
  exit 1
fi
exit 0
STUB
  chmod +x "${STUB_BIN}/git"
}

stub_zz_log() {
  cat > "${STUB_BIN}/zz_log" << 'STUB'
#!/bin/sh
shift
echo "$*" >&2
STUB
  chmod +x "${STUB_BIN}/zz_log"
}

@test "skips the install when git-flow is already available" {
  stub_git_dispatcher yes
  stub zz_install 1 # would fail loudly if actually invoked
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qF "git flow version" "${CALLS_FILE}"
  grep -qF "git flow init" "${CALLS_FILE}"
}

@test "installs via zz_install when git-flow is missing, then proceeds to init" {
  stub_git_dispatcher no
  cat > "${STUB_BIN}/zz_install" << STUB
#!/bin/sh
echo "zz_install \$*" >> "${CALLS_FILE}"
touch "${STUB_BIN}/.installed"
exit 0
STUB
  chmod +x "${STUB_BIN}/zz_install"
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qF "zz_install git-flow apk=gitflow-avh dnf=gitflow yum=gitflow brew=git-flow-avh pacman=gitflow-avh" "${CALLS_FILE}"
  grep -qF "git flow init" "${CALLS_FILE}"
}

@test "errors when zz_install cannot install git-flow" {
  stub_git_dispatcher no
  stub zz_install 1
  stub_zz_log
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"unable to install git-flow"* ]]
  ! grep -qF "git flow init" "${CALLS_FILE}"
}

@test "errors when git-flow is still unavailable after a successful install command" {
  stub_git_dispatcher no
  stub zz_install 0 # "succeeds" but never touches .installed marker
  stub_zz_log
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"still unavailable after install attempt"* ]]
}
