#!/usr/bin/sh

# Audit Composer dependencies for known vulnerabilities and report via reviewdog.

set -e
if (set -o pipefail) 2>/dev/null; then
  set -o pipefail
fi

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

if ! command -v reviewdog >/dev/null 2>&1; then
  echo "Error: reviewdog could not be found. Please install it to run this action." >&2
  exit 1
fi

# Token resolution (input vs GITHUB_TOKEN) happens in setup-reviewdog.
if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
  echo "Error: GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN is required" >&2
  exit 1
fi

if ! command -v composer >/dev/null 2>&1; then
  echo "Error: composer could not be found. Please install it to run this action." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq could not be found. Please install it to run this action." >&2
  exit 1
fi

REVIEWDOG_NAME="${REVIEWDOG_NAME:-composer-audit}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-${TOMGRV_REVIEWDOG_REPORTER:-github-check}}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="nofilter"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"
MAX_DIAGNOSTICS="${MAX_DIAGNOSTICS:-40}"

echo "Running composer audit..." >&2

# Installed versions are needed to work out, per advisory, whether the locked
# version actually falls in the affected range and what the lowest version
# clearing all matching ranges is.
LOCKED_JSON="$(composer show --locked --format=json --no-interaction 2>/dev/null \
  | jq -c '[(.locked // [])[] | {key: .name, value: .version}] | from_entries' 2>/dev/null || true)"
[ -n "${LOCKED_JSON}" ] || LOCKED_JSON='{}'

# Requirements can be declared in a local path repository's composer.json
# rather than (or in addition to) the root one, so collect every manifest
# reachable from composer.lock to locate suggestions correctly.
MANIFEST_PATHS="composer.json"
if [ -f "composer.lock" ]; then
  PATH_REPO_MANIFESTS="$(jq -r '
      ((.packages // []) + (."packages-dev" // []))
      | .[]
      | select(.dist.type == "path" and (.dist.url // "") != "")
      | .dist.url + "/composer.json"
    ' composer.lock 2>/dev/null || true)"
  if [ -n "${PATH_REPO_MANIFESTS}" ]; then
    MANIFEST_PATHS="$(printf '%s\n%s\n' "${MANIFEST_PATHS}" "${PATH_REPO_MANIFESTS}")"
  fi
fi

FILES_JSON_TMP="$(mktemp)"
trap 'rm -f "${FILES_JSON_TMP}"' EXIT
printf '%s\n' "${MANIFEST_PATHS}" | while IFS= read -r manifest; do
  [ -n "${manifest}" ] || continue
  [ -f "${manifest}" ] || continue
  jq -n --arg p "${manifest}" --rawfile c "${manifest}" '{($p): $c}'
done | jq -s 'add // {}' > "${FILES_JSON_TMP}"

exit_code=0
# shellcheck disable=SC2086
{ composer audit --locked --format=json --no-interaction 2>/dev/null || true; } | \
  jq -f "$(dirname "$0")/rdjson.jq" --slurpfile filesJsonArr "${FILES_JSON_TMP}" --argjson locked "${LOCKED_JSON}" --argjson maxDiagnostics "${MAX_DIAGNOSTICS}" | \
  reviewdog \
    -f=rdjson \
    -name="${REVIEWDOG_NAME}" \
    -reporter="${REVIEWDOG_REPORTER}" \
    -level="${REVIEWDOG_LEVEL}" \
    -filter-mode="${REVIEWDOG_FILTER_MODE}" \
    -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
    ${REVIEWDOG_FLAGS} || exit_code=$?
exit $exit_code
