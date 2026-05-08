#!/usr/bin/sh

# dispatch.sh — Run any action locally by name, with sensible GITHUB_* defaults.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Print the description of an action from its action.yml
_action_description() {
  grep -m1 'description:' "${SCRIPT_DIR}/${1}/action.yml" 2>/dev/null \
    | sed 's/^[[:space:]]*description:[[:space:]]*//' \
    | tr -d "'"
}

# Display help
_help() {
  printf 'Usage: %s <action> [args...]\n\n' "$(basename "$0")" >&2
  printf 'Run a GitHub Action locally with sensible defaults.\n\n' >&2
  printf 'Available actions:\n' >&2
  for _dir in "${SCRIPT_DIR}"/*/; do
    _name=$(basename "$_dir")
    if [ -f "${_dir}run.sh" ]; then
      _desc=$(_action_description "$_name")
      printf '  %-30s %s\n' "$_name" "$_desc" >&2
    fi
  done
  printf '\nEnvironment variables:\n' >&2
  printf '  %-28s %s\n' GITHUB_TOKEN        'Authentication token (required by most actions)' >&2
  printf '  %-28s %s\n' GITHUB_WORKSPACE    'Working directory (default: current directory)' >&2
  printf '  %-28s %s\n' GITHUB_REPOSITORY   'owner/repo (default: inferred from git remote)' >&2
  printf '  %-28s %s\n' GITHUB_REF          'Git ref (default: current branch)' >&2
  printf '  %-28s %s\n' GITHUB_SHA          'Commit SHA (default: HEAD)' >&2
  printf '\nExamples:\n' >&2
  printf '  GITHUB_TOKEN=$TOKEN %s check-composer\n' "$(basename "$0")" >&2
  printf '  GITHUB_TOKEN=$TOKEN %s run-phpstan app,src\n' "$(basename "$0")" >&2
}

ACTION="${1:-}"

if [ -z "$ACTION" ] || [ "$ACTION" = "--help" ] || [ "$ACTION" = "-h" ]; then
  _help
  exit 0
fi

shift

# Set default GITHUB_* environment variables if not already set
export GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
export GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-$(git remote get-url origin 2>/dev/null | sed 's|.*github\.com[:/]||; s|\.git$||' || echo '')}"
export GITHUB_REF="${GITHUB_REF:-$(git symbolic-ref HEAD 2>/dev/null || echo 'refs/heads/main')}"
export GITHUB_SHA="${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo '')}"
export GITHUB_EVENT_NAME="${GITHUB_EVENT_NAME:-push}"
export GITHUB_ACTOR="${GITHUB_ACTOR:-$(git config user.name 2>/dev/null || echo '')}"
export GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/stdout}"

ACTION_DIR="${SCRIPT_DIR}/${ACTION}"

if [ ! -d "$ACTION_DIR" ]; then
  printf '::error::Unknown action: %s\n' "$ACTION" >&2
  printf "Run '%s --help' for a list of available actions.\n" "$(basename "$0")" >&2
  exit 1
fi

if [ ! -f "${ACTION_DIR}/run.sh" ]; then
  printf '::error::Action %s has no run.sh (composite-only action, use it in a workflow instead)\n' "$ACTION" >&2
  exit 1
fi

exec sh "${ACTION_DIR}/run.sh" "$@"
