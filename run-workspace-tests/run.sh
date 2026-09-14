#!/bin/sh
set -eu

if [ -z "${WORKSPACE:-}" ]; then
    zz_log e "WORKSPACE (inputs.workspace) is required"
    exit 1
fi

run-workspace-tests "$WORKSPACE"
