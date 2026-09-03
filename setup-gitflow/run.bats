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

@test "skips the install when git-flow is already available" {
  stub_git_dispatcher yes
  stub apt-get 1 # would fail loudly if actually invoked
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qF "git flow version" "${CALLS_FILE}"
  grep -qF "git flow init" "${CALLS_FILE}"
}

@test "installs via apt-get when git-flow is missing, then proceeds to init" {
  stub_git_dispatcher no
  cat > "${STUB_BIN}/apt-get" << STUB
#!/bin/sh
echo "apt-get \$*" >> "${CALLS_FILE}"
touch "${STUB_BIN}/.installed"
exit 0
STUB
  chmod +x "${STUB_BIN}/apt-get"
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qF "apt-get update" "${CALLS_FILE}"
  grep -qF "apt-get install -y git-flow" "${CALLS_FILE}"
  grep -qF "git flow init" "${CALLS_FILE}"
}

@test "errors when no supported package manager is found" {
  stub_git_dispatcher no
  # Exclusive PATH -- this sandbox has a real apt-get on it, which would
  # otherwise mask the branch under test. Invoke via the script's own
  # shebang (an absolute path) rather than `sh "$SCRIPT"`, so resolving
  # `sh` itself doesn't need PATH.
  run env PATH="${STUB_BIN}" "${SCRIPT}"
  [ "$status" -ne 0 ]
  [[ "$output" == *"no supported package manager found"* ]]
}

@test "errors when git-flow is still unavailable after a successful install command" {
  stub_git_dispatcher no
  stub apt-get 0 # "succeeds" but never touches .installed marker
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"still unavailable after install attempt"* ]]
}

@test "passes master/develop branch config through to git flow init" {
  stub_git_dispatcher yes
  export GITFLOW_MASTER_BRANCH="trunk"
  export GITFLOW_DEVELOP_BRANCH="dev"
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qF "git config gitflow.branch.master trunk" "${CALLS_FILE}"
  grep -qF "git config gitflow.branch.develop dev" "${CALLS_FILE}"
}
