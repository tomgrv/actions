#!/usr/bin/sh

set -eu

DEP="${DEP:-deploy}"
OPTIONS="${OPTIONS:-}"
SELECTOR="${SELECTOR:-all}"
TARGET_BRANCH="${TARGET_BRANCH:-}"
TARGET_TAG="${TARGET_TAG:-}"
TARGET_ENVIRONMENT="${TARGET_ENVIRONMENT:-}"
BRANCH_SCOPE="${BRANCH_SCOPE:-}"
ENVIRONMENT="${ENVIRONMENT:-}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-check}"

args="${DEP} ${OPTIONS}"

if [ -n "${TARGET_BRANCH}" ]; then
    args="${args} --branch=${TARGET_BRANCH}"
fi
if [ -n "${TARGET_TAG}" ]; then
    args="${args} --tag=${TARGET_TAG}"
fi
if [ -n "${BRANCH_SCOPE}" ]; then
    args="${args} --branch-scope=${BRANCH_SCOPE}"
fi

environment="${ENVIRONMENT}"
if [ -z "${environment}" ]; then
    environment="${TARGET_ENVIRONMENT}"
fi

# Callers backslash-escape '&' in their selector inputs (e.g. "alias=host\&all")
# so GitHub Actions/YAML don't mangle it before it reaches this shell. Normalize
# it back to a plain '&' here rather than relying on the caller leaving the
# value unquoted for us - quoting below is otherwise correct and safer.
selector=$(printf '%s' "${SELECTOR}" | sed 's/\\&/\&/g')
# Only append env=<environment> when the caller hasn't already filtered by
# env themselves (e.g. selector: env=production) - appending unconditionally
# would produce a duplicated env= term that can change Deployer's host match.
case "${selector}" in
    *env=*) ;;
    *)
        if [ -n "${environment}" ]; then
            selector="${selector}&env=${environment}"
        fi
        ;;
esac

echo "Running Deployer command: ${args} -- ${selector}" >&2

# Redirect (not pipe) to a log file so `dep`'s own exit status is captured
# directly and portably (no bash-only pipefail needed), then replay the log
# so it still appears in the job output.
log_file=$(mktemp)
set +e
# shellcheck disable=SC2086
"${HOME}/.composer/vendor/bin/dep" ${args} -- "${selector}" >"${log_file}" 2>&1
status=$?
set -e

cat "${log_file}" >&2

# Report Deployer warnings/errors as reviewdog check annotations. Best-effort:
# never let reviewdog's own outcome affect the step's exit status below.
jq -R -s -f "${GITHUB_ACTION_PATH}/rdjson.jq" <"${log_file}" |
    reviewdog \
        -f=rdjson \
        -name="deployer" \
        -reporter="${REVIEWDOG_REPORTER}" \
        -filter-mode=nofilter \
        -fail-level=none >&2 || true

url=$(grep -o '##KLICK_DEPLOY_URL##.*' "${log_file}" | tail -n1 | sed 's/##KLICK_DEPLOY_URL##//')
if [ -n "${url}" ]; then
    printf 'deploy-url=%s\n' "${url}"
fi

exit "${status}"
