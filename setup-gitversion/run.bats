# @format

# Tests setup-gitversion/run.sh: idempotently install the gitversion toolchain.
# gv/bump-tag/bump-changelog/bump-version are installed by this action's own
# earlier "Setup scripts toolchain" step (setup-scripts@v2, scripts: zz-log
# gv bump-tag bump-changelog bump-version) -- run.sh itself only builds the
# docker-gitversion wrapper/gitversion symlink and then verifies everything
# actually landed on PATH.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCRIPT="${REPO_ROOT}/setup-gitversion/run.sh"
  STUB_BIN="$(mktemp -d)"
  export PATH="${STUB_BIN}:${PATH}"
  # run.sh always does `export PATH="${INSTALL_BIN_DIR:-/usr/local/bin}:$PATH"`
  # even when the install is skipped -- point it at STUB_BIN too, so a real
  # gv this dev container may already have installed system-wide doesn't
  # shadow the stub once that line re-prepends its default.
  export INSTALL_BIN_DIR="${STUB_BIN}"
  unset GITHUB_PATH
  # zz-log itself needs to resolve here -- in real CI it's put on PATH by
  # the setup-scripts composite step; stub a minimal stand-in.
  cat > "${STUB_BIN}/zz-log" <<'EOF'
#!/bin/sh
shift
echo "$*" >&2
EOF
  chmod +x "${STUB_BIN}/zz-log"
  # Keep the image cache inside the sandbox and never reach a real docker.
  export GITVERSION_CACHE_DIR="${STUB_BIN}/cache"
  DOCKER_LOG="${STUB_BIN}/docker.log"
  export DOCKER_LOG
  stub_docker
}

teardown() {
  rm -rf "${STUB_BIN}"
}

# docker stand-in: logs every call; behaviour is driven by env vars.
#   DOCKER_HAS_IMAGE=1  -> `image inspect` succeeds (image already local)
#   DOCKER_LOAD_EXIT    -> exit code of `docker load` (default 0)
#   DOCKER_PULL_EXIT    -> exit code of `docker pull` (default 0)
# `docker save -o <file>` writes a tiny file at <file>.
stub_docker() {
  cat > "${STUB_BIN}/docker" <<'STUB'
#!/bin/sh
echo "docker $*" >> "${DOCKER_LOG}"
case "$1" in
  image) [ "${DOCKER_HAS_IMAGE:-0}" = 1 ] && exit 0; exit 1 ;;
  load) cat > /dev/null; exit "${DOCKER_LOAD_EXIT:-0}" ;;
  pull) exit "${DOCKER_PULL_EXIT:-0}" ;;
  save) [ "$2" = "-o" ] && echo image > "$3"; exit 0 ;;
esac
exit 0
STUB
  chmod +x "${STUB_BIN}/docker"
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

stub_scripts_toolchain() {
  for name in gv bump-tag bump-changelog bump-version; do
    stub "$name" 0
  done
}

stub_toolchain_present() {
  stub_scripts_toolchain
  stub gitversion 0
}

@test "skips building the docker wrapper when gitversion is already on PATH" {
  stub_toolchain_present
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "builds the docker wrapper when gitversion is missing, given gv/bump-tag/bump-changelog/bump-version already installed" {
  stub_scripts_toolchain
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -x "${STUB_BIN}/docker-gitversion" ]
  [ -L "${STUB_BIN}/gitversion" ]
}

@test "errors clearly when gv/bump-tag/bump-changelog/bump-version weren't installed by the earlier setup-scripts step" {
  # None of the four stubbed -- simulates the "Setup scripts toolchain" step
  # never having run or having failed to actually land them on PATH.
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not on PATH after install"* ]]
}

@test "appends the install bin dir to GITHUB_PATH when set" {
  stub_toolchain_present
  gh_path_file="$(mktemp)"
  export GITHUB_PATH="$gh_path_file"
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qF "$STUB_BIN" "$gh_path_file"
  rm -f "$gh_path_file"
}

@test "pulls the image and archives it on a cache miss" {
  stub_scripts_toolchain
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qF "docker pull -q gittools/gitversion:6.5.1" "$DOCKER_LOG"
  grep -qF "docker save -o ${GITVERSION_CACHE_DIR}/gitversion-6.5.1.tar gittools/gitversion:6.5.1" "$DOCKER_LOG"
  [ -f "${GITVERSION_CACHE_DIR}/gitversion-6.5.1.tar.gz" ]
}

@test "loads the cached archive instead of pulling on a cache hit" {
  stub_scripts_toolchain
  mkdir -p "$GITVERSION_CACHE_DIR"
  printf 'x' | gzip > "${GITVERSION_CACHE_DIR}/gitversion-6.5.1.tar.gz"
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qF "docker load" "$DOCKER_LOG"
  ! grep -qF "docker pull" "$DOCKER_LOG"
}

@test "does nothing with the image when it is already local" {
  stub_scripts_toolchain
  DOCKER_HAS_IMAGE=1 run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  ! grep -qE "docker (load|pull|save)" "$DOCKER_LOG"
}

@test "falls back to pulling when the cached archive fails to load" {
  stub_scripts_toolchain
  mkdir -p "$GITVERSION_CACHE_DIR"
  printf 'x' | gzip > "${GITVERSION_CACHE_DIR}/gitversion-6.5.1.tar.gz"
  DOCKER_LOAD_EXIT=1 run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qF "docker pull" "$DOCKER_LOG"
  [[ "$output" == *"cached image archive unusable"* ]]
}

@test "a failed pre-pull is not fatal and leaves no archive behind" {
  stub_scripts_toolchain
  DOCKER_PULL_EXIT=1 run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -x "${STUB_BIN}/docker-gitversion" ]
  [ ! -e "${GITVERSION_CACHE_DIR}/gitversion-6.5.1.tar.gz" ]
}

@test "uses GITVERSION_VERSION for the image tag and archive name" {
  stub_scripts_toolchain
  GITVERSION_VERSION=6.0.0 run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qF "docker pull -q gittools/gitversion:6.0.0" "$DOCKER_LOG"
  [ -f "${GITVERSION_CACHE_DIR}/gitversion-6.0.0.tar.gz" ]
}

@test "skips the image step when gitversion is already on PATH" {
  stub_toolchain_present
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [ ! -e "$DOCKER_LOG" ]
}
