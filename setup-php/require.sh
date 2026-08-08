#!/usr/bin/sh

set -e

REQUIRE="${REQUIRE:-}"

if [ -z "${REQUIRE}" ]; then
    exit 0
fi

GLOBAL_BIN="$(composer config -g home)/vendor/bin"
echo "${GLOBAL_BIN}" >> "${GITHUB_PATH}"

IFS=','
for pkg in ${REQUIRE}; do
    # Trim surrounding whitespace so "a, b" and "a,b" behave the same.
    pkg=$(echo "${pkg}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "${pkg}" ] && continue

    pkg_name="${pkg%%:*}"

    if composer global show "${pkg_name}" > /dev/null 2>&1; then
        echo "::notice::${pkg_name} is already installed globally, skipping" >&2
        continue
    fi

    echo "Installing ${pkg} globally via Composer" >&2
    composer global require --no-interaction --no-progress --ansi "${pkg}"
done
