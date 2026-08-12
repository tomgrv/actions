#!/bin/sh

# Orchestrate all Dockerfile checks and pipe results to reviewdog.

set -e

DOCKERFILE="${DOCKERFILE:=./Dockerfile}"
STRICT="${STRICT:=false}"
ACTION_PATH="${ACTION_PATH:=$(cd "$(dirname "$0")" && pwd)}"

# Ensure reviewdog is available
if ! command -v reviewdog >/dev/null 2>&1; then
  echo "Error: reviewdog is not installed. Setup reviewdog before this action." >&2
  exit 1
fi

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE" ]; then
  echo "Error: Dockerfile not found at $DOCKERFILE" >&2
  exit 1
fi

# Get context directory (parent of Dockerfile)
CONTEXT_DIR=$(dirname "$DOCKERFILE")

# Run all checks and collect output
errors=()
warnings=()

# 1. Check for pinned versions (required)
if ! "$ACTION_PATH/check-pinned-versions.sh" "$CONTEXT_DIR" 2>&1 | while read -r line; do
  errors+=("$line")
  echo "$line" | reviewdog -efm="%f:%l:%m" -reporter="${REVIEWDOG_REPORTER:-github-check}" -level=error
done; then
  : # Capture output
fi

# 2. Check .dockerignore (warning)
if ! "$ACTION_PATH/check-dockerignore.sh" "$CONTEXT_DIR" 2>&1 | while read -r line; do
  if [ "$STRICT" = "true" ]; then
    errors+=("$line")
    echo "$line" | reviewdog -efm="%f:%l:%m" -reporter="${REVIEWDOG_REPORTER:-github-check}" -level=error
  else
    warnings+=("$line")
    echo "$line" | reviewdog -efm="%f:%l:%m" -reporter="${REVIEWDOG_REPORTER:-github-check}" -level=warning
  fi
done; then
  : # Capture output
fi

# 3. Check multi-stage (warning)
if ! "$ACTION_PATH/check-multistage.sh" "$CONTEXT_DIR" 2>&1 | while read -r line; do
  if [ "$STRICT" = "true" ]; then
    errors+=("$line")
    echo "$line" | reviewdog -efm="%f:%l:%m" -reporter="${REVIEWDOG_REPORTER:-github-check}" -level=error
  else
    warnings+=("$line")
    echo "$line" | reviewdog -efm="%f:%l:%m" -reporter="${REVIEWDOG_REPORTER:-github-check}" -level=warning
  fi
done; then
  : # Capture output
fi

# 4. Check non-root user (warning)
if ! "$ACTION_PATH/check-nonroot-user.sh" "$CONTEXT_DIR" 2>&1 | while read -r line; do
  if [ "$STRICT" = "true" ]; then
    errors+=("$line")
    echo "$line" | reviewdog -efm="%f:%l:%m" -reporter="${REVIEWDOG_REPORTER:-github-check}" -level=error
  else
    warnings+=("$line")
    echo "$line" | reviewdog -efm="%f:%l:%m" -reporter="${REVIEWDOG_REPORTER:-github-check}" -level=warning
  fi
done; then
  : # Capture output
fi

# 5. Check healthcheck (warning)
if ! "$ACTION_PATH/check-healthcheck.sh" "$CONTEXT_DIR" 2>&1 | while read -r line; do
  if [ "$STRICT" = "true" ]; then
    errors+=("$line")
    echo "$line" | reviewdog -efm="%f:%l:%m" -reporter="${REVIEWDOG_REPORTER:-github-check}" -level=error
  else
    warnings+=("$line")
    echo "$line" | reviewdog -efm="%f:%l:%m" -reporter="${REVIEWDOG_REPORTER:-github-check}" -level=warning
  fi
done; then
  : # Capture output
fi

# Set outputs
{
  echo "issues-found=$((${#errors[@]} + ${#warnings[@]}))"
  echo "checks-failed=${#errors[@]}"
  echo "checks-warned=${#warnings[@]}"
} >> "$GITHUB_OUTPUT"

# Exit with error if any required checks failed
if [ ${#errors[@]} -gt 0 ]; then
  exit 1
fi

exit 0
