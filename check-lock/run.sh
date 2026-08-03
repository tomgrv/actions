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

# `composer validate --strict` reports three independent things in one pass: schema
# errors/warnings, publish-readiness (missing description, license, etc.), and lock
# staleness (content-hash mismatch, under "# Lock file errors"). composer.lock is not
# required: packages and libraries commonly don't commit one, and validate still
# checks the manifest itself in that case.
_check_composer() {
  _dir="$1"

  [ -f "${_dir}/composer.json" ] || return 0

  if ! command -v composer >/dev/null 2>&1; then
    _add "${_dir}/composer.json" ERROR \
      "composer.json found but composer is not available on this runner, so it could not be validated. Add a Composer setup step before this action."
    return 0
  fi

  echo "Validating composer.json / composer.lock in ${_dir}..." >&2

  if _out=$(cd "${_dir}" && composer validate --strict --no-interaction 2>&1); then
    _exit=0
  else
    _exit=$?
  fi
  printf '%s\n' "${_out}" >&2

  _found=0

  # Composer groups every finding under a "# <Section>" header followed by "- "
  # bullets (e.g. "# Lock file errors", "# General warnings", "# Publish errors").
  # Which stream (stdout/stderr) carries that report, and which carries the
  # root-user/version-detection preamble, differs by composer version and by
  # whether the result is clean or not — so rather than filtering preamble text
  # by pattern, extract by this structure instead: it is unaffected by whatever
  # boilerplate surrounds it. A schema violation severe enough to crash before
  # composer reaches its own report (bad name pattern, unparseable JSON) prints
  # an indented "- " with no "# " section around it, so it never matches this
  # parser and falls through to the generic exit-code fallback below instead of
  # being torn into unrelated diagnostic lines.
  _sections=$(printf '%s\n' "${_out}" | awk '
    /^# / { section = $0; sub(/^# /, "", section); next }
    /^- / { item = $0; sub(/^- /, "", item); print section "\t" item }
  ')

  if [ -n "${_sections}" ]; then
    _lock_errors=$(printf '%s\n' "${_sections}" | awk -F'\t' '$1 == "Lock file errors" { print $2 }')
    if [ -n "${_lock_errors}" ]; then
      _found=1
      _add "${_dir}/composer.lock" ERROR "composer.lock is out of sync with composer.json.
Run \`composer update --lock\` and commit the updated lock file.
${_lock_errors}"
    fi

    _tab=$(printf '\t')
    while IFS="${_tab}" read -r _section _item; do
      [ "${_section}" = "Lock file errors" ] && continue
      _found=1
      case "${_section}" in
        *[Ww]arning*) _severity=WARNING ;;
        *) _severity=ERROR ;;
      esac
      _add "${_dir}/composer.json" "${_severity}" "${_item}"
    done <<EORD
${_sections}
EORD
  fi

  if [ "${_found}" -eq 0 ] && [ "${_exit}" -ne 0 ]; then
    _add "${_dir}/composer.json" ERROR "composer validate failed (exit ${_exit}), so composer.json/composer.lock could not be verified.
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

set -f
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
set +f

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
