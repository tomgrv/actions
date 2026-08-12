#!/bin/sh

# Run all BATS tests for composite actions.
#
# Usage: ./test/run-all-tests.sh [options]
#   -v, --verbose       Show detailed test output
#   -f, --filter PATTERN Only run tests matching PATTERN
#   -q, --quiet         Suppress test output
#   -h, --help          Show this help message

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

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

_help() {
  cat >&2 <<'EOF'
Run all BATS tests for composite actions.

Usage: ./test/run-all-tests.sh [options]

Options:
  -v, --verbose       Show detailed test output
  -f, --filter PATTERN Only run tests matching PATTERN
  -q, --quiet         Suppress test output
  -h, --help          Show this help message

Examples:
  # Run all tests
  ./test/run-all-tests.sh

  # Run tests with verbose output
  ./test/run-all-tests.sh -v

  # Run only resolve-environment tests
  ./test/run-all-tests.sh -f resolve-environment

  # Run only tests with 'changes' in the name
  ./test/run-all-tests.sh -f changes
EOF
}

# Check if bats is installed
if ! command -v bats >/dev/null 2>&1; then
  echo "Error: bats is not installed. Install it with: npm install -g bats" >&2
  exit 1
fi

# Collect test files
TEST_FILES=""
if [ -n "${FILTER}" ]; then
  TEST_FILES=$(find "${SCRIPT_DIR}" -name "*.bats" -path "*${FILTER}*" 2>/dev/null | sort)
else
  TEST_FILES=$(find "${SCRIPT_DIR}" -name "*.bats" -type f 2>/dev/null | sort)
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
