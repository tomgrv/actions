#!/usr/bin/sh

set -e

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
  if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "::error::GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN is required" >&2
    exit 1
  fi
  echo "::notice::REVIEWDOG_GITHUB_API_TOKEN not set, using GITHUB_TOKEN" >&2
  export REVIEWDOG_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
fi

if ! command -v reviewdog >/dev/null 2>&1; then
  echo "::error::reviewdog could not be found. Please install it to run this action." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "::error::jq could not be found. Please install it to run this action." >&2
  exit 1
fi

REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-pr-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="${REVIEWDOG_FILTER_MODE:-nofilter}"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-error}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

PATHS="${1:-.}"
MAX_DETAILS=20

FINDINGS=$(mktemp)
DRIFT_FILES=''
trap 'rm -f "${FINDINGS}"' EXIT

# Record one diagnostic. Multi-line messages are folded onto a single TSV line;
# rdjson.jq unfolds the literal \n sequences back into real newlines.
_add() {
  _path=$(printf '%s' "$1" | sed 's|^\./||')
  _severity="$2"
  _message=$(printf '%s' "$3" | awk '{ gsub(/\t/, " "); printf "%s%s", (NR > 1 ? "\\n" : ""), $0 } END { printf "\n" }')

  printf '%s\t%s\t%s\n' "${_path}" "${_severity}" "${_message}" >>"${FINDINGS}"

  case ",${DRIFT_FILES}," in
    *",${_path},"*) ;;
    *) DRIFT_FILES="${DRIFT_FILES:+${DRIFT_FILES},}${_path}" ;;
  esac
}

# composer validate reports lock staleness by comparing the content-hash stored in
# composer.lock against composer.json. Only the "Lock file errors" section is kept
# here: schema and publish warnings are check-composer's job, not this action's.
_check_composer() {
  _dir="$1"

  [ -f "${_dir}/composer.json" ] || return 0
  [ -f "${_dir}/composer.lock" ] || return 0

  if ! command -v composer >/dev/null 2>&1; then
    _add "${_dir}/composer.lock" ERROR \
      "composer.lock found but composer is not available on this runner, so lock coherence could not be verified. Add a Composer setup step before this action."
    return 0
  fi

  echo "Checking composer lock coherence in ${_dir}..." >&2

  if _out=$(cd "${_dir}" && composer validate --no-check-all --no-check-publish --no-interaction 2>&1); then
    _exit=0
  else
    _exit=$?
  fi
  printf '%s\n' "${_out}" >&2

  _errors=$(printf '%s\n' "${_out}" | awk '
    /^# Lock file errors/ { inlock = 1; next }
    /^# / { inlock = 0 }
    inlock && /^- / { sub(/^- /, ""); print }
  ')

  if [ -n "${_errors}" ]; then
    _add "${_dir}/composer.lock" ERROR "composer.lock is out of sync with composer.json.
Run \`composer update --lock\` and commit the updated lock file.
${_errors}"
  elif [ "${_exit}" -ne 0 ]; then
    _add "${_dir}/composer.lock" ERROR "composer validate failed (exit ${_exit}) for a reason other than lock drift, so lock coherence could not be verified.
${_out}"
  fi

  return 0
}

# `npm ci` is what CI actually runs, and it refuses to install when the lock does not
# match the manifests. --dry-run --package-lock-only reproduces exactly that check
# without installing anything or writing to the lock file.
_check_npm() {
  _dir="$1"

  [ -f "${_dir}/package.json" ] || return 0
  [ -f "${_dir}/package-lock.json" ] || return 0

  if ! command -v npm >/dev/null 2>&1; then
    _add "${_dir}/package-lock.json" ERROR \
      "package-lock.json found but npm is not available on this runner, so lock coherence could not be verified. Add a Node setup step before this action."
    return 0
  fi

  # --workspaces is only valid when the manifest actually declares workspaces.
  _workspaces=''
  if jq -e '.workspaces' "${_dir}/package.json" >/dev/null 2>&1; then
    _workspaces='--workspaces --include-workspace-root'
  fi

  echo "Checking npm lock coherence in ${_dir}..." >&2

  # shellcheck disable=SC2086
  if _out=$(cd "${_dir}" && npm ci --dry-run --package-lock-only --no-audit --no-fund ${_workspaces} 2>&1); then
    _exit=0
  else
    _exit=$?
  fi
  printf '%s\n' "${_out}" >&2

  if [ "${_exit}" -eq 0 ]; then
    return 0
  fi

  if ! printf '%s\n' "${_out}" | grep -q 'can only install packages when your package.json and package-lock.json'; then
    _add "${_dir}/package-lock.json" ERROR "npm ci --dry-run failed (exit ${_exit}) for a reason other than lock drift, so lock coherence could not be verified.
${_out}"
    return 0
  fi

  _detail=$(printf '%s\n' "${_out}" | awk '
    /^npm error (Missing|Invalid|Added|Removed):/ { sub(/^npm error /, ""); print }
  ')
  _total=$(printf '%s\n' "${_detail}" | grep -c . || true)
  _shown=$(printf '%s\n' "${_detail}" | head -n "${MAX_DETAILS}")

  if [ "${_total}" -gt "${MAX_DETAILS}" ]; then
    _shown="${_shown}
... and $((_total - MAX_DETAILS)) more"
  fi

  _add "${_dir}/package-lock.json" ERROR "package-lock.json is out of sync with package.json.
Run \`npm install\` and commit the updated lock file.
${_shown}"

  return 0
}

echo "Checking lock coherence in: ${PATHS}" >&2

_oldifs=$IFS
IFS=','
set -f
# shellcheck disable=SC2086
for _target in ${PATHS}; do
  IFS=$_oldifs

  _target=$(printf '%s' "${_target}" | sed 's|^[[:space:]]*||; s|[[:space:]]*$||; s|/*$||')
  _target="${_target:-.}"

  if [ ! -d "${_target}" ]; then
    echo "::warning::Directory not found, skipping: ${_target}" >&2
    IFS=','
    continue
  fi

  _check_composer "${_target}"
  _check_npm "${_target}"

  IFS=','
done
set +f
IFS=$_oldifs

if [ -s "${FINDINGS}" ]; then
  echo "Lock coherence findings:" >&2
  cat "${FINDINGS}" >&2
fi

exit_code=0
# shellcheck disable=SC2086
jq -R -s -f "$(dirname "$0")/rdjson.jq" <"${FINDINGS}" | \
  reviewdog \
    -f=rdjson \
    -name="lock-coherence" \
    -reporter="${REVIEWDOG_REPORTER}" \
    -level="${REVIEWDOG_LEVEL}" \
    -filter-mode="${REVIEWDOG_FILTER_MODE}" \
    -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
    ${REVIEWDOG_FLAGS} >&2 || exit_code=$?

if [ -s "${FINDINGS}" ]; then
  printf 'has-drift=true\n'
else
  echo "All lock files are in sync." >&2
  printf 'has-drift=false\n'
fi
printf 'drift-files=%s\n' "${DRIFT_FILES}"

exit $exit_code
