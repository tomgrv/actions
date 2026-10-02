#!/bin/sh

# Run all BATS tests for composite actions.
#
# Usage: ./.repo/tests/run-tests.sh [options]
#   -v, --verbose       Show detailed test output
#   -f, --filter PATTERN Only run tests matching PATTERN
#   -q, --quiet         Suppress test output
#   -h, --help          Show this help message

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

_help() {
  cat >&2 <<'EOF'
Run all BATS tests for composite actions.

Usage: ./.repo/tests/run-tests.sh [options]

Options:
  -v, --verbose       Show detailed test output
  -f, --filter PATTERN Only run tests matching PATTERN
  -q, --quiet         Suppress test output
  -h, --help          Show this help message

Examples:
  # Run all tests
  ./.repo/tests/run-tests.sh

  # Run tests with verbose output
  ./.repo/tests/run-tests.sh -v

  # Run only resolve-environment tests
  ./.repo/tests/run-tests.sh -f resolve-environment

  # Run only tests with 'changes' in the name
  ./.repo/tests/run-tests.sh -f changes
EOF
}

VERBOSE=""
FILTER=""
QUIET=""

# Parse arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -v|--verbose) VERBOSE="1"; shift ;;
    -f|--filter) FILTER="$2"; shift 2 ;;
    -q|--quiet) QUIET="1"; shift ;;
    -h|--help) _help; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Every script an action runs through `${{ github.action_path }}/...` must be
# executable, or the step fails with "permission denied" at run time.
NOT_EXEC=""
for action_yml in "${REPO_ROOT}"/*/action.yml; do
  action_dir=$(dirname "${action_yml}")
  for script in $(grep -oE 'action_path }}/[A-Za-z0-9_./-]+' "${action_yml}" | sed 's|.*}}/||'); do
    [ -x "${action_dir}/${script}" ] || NOT_EXEC="${NOT_EXEC} ${action_dir#"${REPO_ROOT}"/}/${script}"
  done
done
if [ -n "${NOT_EXEC}" ]; then
  echo "Error: action scripts are not executable (chmod +x):${NOT_EXEC}" >&2
  exit 1
fi

# Check if bats is installed
if ! command -v bats >/dev/null 2>&1; then
  echo "Error: bats is not installed. Install it with: npm install -g bats" >&2
  exit 1
fi

# Collect test files from action directories
TEST_FILES=""
if [ -n "${FILTER}" ]; then
  TEST_FILES=$(find "${REPO_ROOT}" -maxdepth 2 -name "run.bats" -type f 2>/dev/null | grep -E "${FILTER}" | sort)
else
  TEST_FILES=$(find "${REPO_ROOT}" -maxdepth 2 -name "run.bats" -type f 2>/dev/null | sort)
fi

if [ -z "${TEST_FILES}" ]; then
  echo "No test files found" >&2
  exit 1
fi

# Run tests
echo "Running BATS tests..."
echo ""

if [ -n "${QUIET}" ]; then
  bats ${TEST_FILES} --quiet
elif [ -n "${VERBOSE}" ]; then
  bats ${TEST_FILES} --verbose
else
  bats ${TEST_FILES}
fi
