#!/usr/bin/sh

set -e

REQUIRE="${REQUIRE:-}"

if [ -z "${REQUIRE}" ]; then
    exit 0
fi

GLOBAL_BIN="$(composer config -g home)/vendor/bin"
echo "${GLOBAL_BIN}" >> "${GITHUB_PATH}"

IFS=','
# Disable pathname expansion: a version constraint like "pkg:1.*" must reach
# Composer unchanged, not be glob-expanded against the working directory.
set -f
for pkg in ${REQUIRE}; do
    # Trim surrounding whitespace so "a, b" and "a,b" behave the same.
    pkg=$(printf '%s' "${pkg}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "${pkg}" ] && continue

    pkg_name="${pkg%%:*}"

    if [ -f composer.json ] && composer show "${pkg_name}" > /dev/null 2>&1; then
        echo "::notice::${pkg_name} is already installed locally in vendor/, skipping global install" >&2
        continue
    fi

    if composer global show "${pkg_name}" > /dev/null 2>&1; then
        echo "::notice::${pkg_name} is already installed globally, skipping" >&2
        continue
    fi

    echo "Installing ${pkg} globally via Composer" >&2
    composer global require --no-interaction --no-progress --ansi "${pkg}"
done
set +f
