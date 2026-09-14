#!/bin/sh

set -eu

INPUT_BARE="${1:-false}"
INPUT_OPTIONS="${2:-}"

if [ "${TOMGRV_NODE_SETUP:-}" = 'true' ]; then
    exit 0
fi

BARE_REPO="$(git rev-parse --is-bare-repository 2> /dev/null || echo false)"

if [ "${INPUT_BARE}" != 'true' ] && [ "${BARE_REPO}" != 'true' ] && [ -f package-lock.json ]; then
    python - "${INPUT_OPTIONS}" <<'PY'
import shlex
import subprocess
import sys

options = shlex.split(sys.argv[1]) if sys.argv[1] else []
subprocess.run(["npm", "ci", "--no-progress", "--workspaces", *options], check=True)
PY
fi

echo "TOMGRV_NODE_SETUP=true" >> "$GITHUB_ENV"
