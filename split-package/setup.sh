#!/bin/sh

SPLITSH_BINARY="/usr/local/bin/splitsh-lite"
SPLITSH_VERSION="${1:-${SPLITSH_VERSION-v1.0.1}}"
SPLITSH_ARCH="${2:-${SPLITSH_ARCH:-linux_amd64}}"

if [ -f "${SPLITSH_BINARY}" ]; then
    echo "splitsh-lite already installed at ${SPLITSH_BINARY}" >&2
    exit 0
fi

ARCHIVE_NAME="lite_${SPLITSH_ARCH}.tar.gz"
ARCHIVE_URL="https://github.com/splitsh/lite/releases/download/${SPLITSH_VERSION}/${ARCHIVE_NAME}"
ARCHIVE_TMP="/tmp/${ARCHIVE_NAME}"

echo "Downloading splitsh-lite ${SPLITSH_VERSION} (${SPLITSH_ARCH}) to ${ARCHIVE_TMP}"

curl -fsSL "${ARCHIVE_URL}" -o "${ARCHIVE_TMP}" || {
    echo "::error::Failed to download splitsh-lite from ${ARCHIVE_URL}" >&2
    exit 1
}

if [ -n "${SPLITSH_CHECKSUM}" ]; then
    printf '%s  %s\n' "${SPLITSH_CHECKSUM}" "${ARCHIVE_TMP}" | sha256sum -c -
fi

echo "Extracting splitsh-lite to ${SPLITSH_BINARY}" >&2
if sudo tar -xzf "${ARCHIVE_TMP}" -C "/usr/local/bin"; then
    sudo chmod +x "${SPLITSH_BINARY}"
    rm -f "${ARCHIVE_TMP}"
else
    echo "::error::Failed to extract splitsh-lite to ${SPLITSH_BINARY}" >&2
    rm -f "${ARCHIVE_TMP}"
    exit 1
fi

echo "splitsh-lite installed" >&2
