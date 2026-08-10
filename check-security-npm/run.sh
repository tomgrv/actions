#!/usr/bin/sh

# Audit npm dependencies for known vulnerabilities and report via reviewdog.

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

# Token resolution (input vs GITHUB_TOKEN) happens in setup-reviewdog; this
# is a setup concern, not a security finding: plain log only, no GitHub
# annotation (see .github/instructions/action-creation.md).
if [ -z "${REVIEWDOG_GITHUB_API_TOKEN:-}" ]; then
  echo "Error: GITHUB_TOKEN or REVIEWDOG_GITHUB_API_TOKEN is required" >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "Error: npm could not be found. Please install it to run this action." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq could not be found. Please install it to run this action." >&2
  exit 1
fi

REVIEWDOG_NAME="${REVIEWDOG_NAME:-npm-audit}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="nofilter"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"
MAX_DIAGNOSTICS="${MAX_DIAGNOSTICS:-40}"

echo "Running npm audit..." >&2

WORKSPACES_FLAGS=""
if [ -f "package.json" ] && jq -e '.workspaces' package.json >/dev/null 2>&1; then
  WORKSPACES_FLAGS="--workspaces"
fi

# Direct dependencies can be declared in a workspace member's package.json
# rather than (or in addition to) the root one, so collect every manifest
# reachable from package-lock.json to locate suggestions correctly.
MANIFEST_PATHS="package.json"
if [ -n "${WORKSPACES_FLAGS}" ] && [ -f "package-lock.json" ]; then
  WORKSPACE_MANIFESTS="$(jq -r '
      (.packages // {})
      | keys[]
      | select(. != "" and (test("(^|/)node_modules(/|$)") | not))
      | . + "/package.json"
    ' package-lock.json 2>/dev/null || true)"
  if [ -n "${WORKSPACE_MANIFESTS}" ]; then
    MANIFEST_PATHS="$(printf '%s\n%s\n' "${MANIFEST_PATHS}" "${WORKSPACE_MANIFESTS}")"
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
{ npm audit ${WORKSPACES_FLAGS} --audit-level moderate --package-lock-only --json 2>/dev/null || true; } \
  | jq -f "$(dirname "$0")/rdjson.jq" --slurpfile filesJsonArr "${FILES_JSON_TMP}" --argjson maxDiagnostics "${MAX_DIAGNOSTICS}" \
  | reviewdog \
      -f=rdjson \
      -name="${REVIEWDOG_NAME}" \
      -reporter="${REVIEWDOG_REPORTER}" \
      -level="${REVIEWDOG_LEVEL}" \
      -filter-mode="${REVIEWDOG_FILTER_MODE}" \
      -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
      ${REVIEWDOG_FLAGS} || exit_code=$?
exit $exit_code
