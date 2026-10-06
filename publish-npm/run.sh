#!/bin/sh

# Publish an npm package to the registry using GitHub's OIDC trusted publishers.

set -e
if (set -o pipefail) 2>/dev/null; then
  set -o pipefail
fi

if [ -n "${GITHUB_WORKSPACE:-}" ]; then
  cd "${GITHUB_WORKSPACE}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

PACKAGE_PATH="${PACKAGE_PATH:-.}"
REGISTRY_URL="${REGISTRY_URL:-https://registry.npmjs.org/}"
PROVENANCE="${PROVENANCE:-true}"
DIST_TAG="${DIST_TAG:-latest}"
DRY_RUN="${DRY_RUN:-false}"

# Validate required tools
if ! command -v node >/dev/null 2>&1; then
  zz_log e "node could not be found. Please install Node.js to run this action."
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  zz_log e "npm could not be found. Please install npm to run this action."
  exit 1
fi

# Navigate to package directory
if [ "${PACKAGE_PATH}" != "." ]; then
  cd "${PACKAGE_PATH}" || { zz_log e "Could not change to directory '${PACKAGE_PATH}'"; exit 1; }
fi

# Validate package.json exists
if [ ! -f "package.json" ]; then
  zz_log e "package.json not found in '${PACKAGE_PATH}'"
  exit 1
fi

# Extract package metadata using node (more reliable than jq for various shells)
PACKAGE_NAME=$(node -e "console.log(require('./package.json').name)")
PACKAGE_VERSION=$(node -e "console.log(require('./package.json').version)")

if [ -z "${PACKAGE_NAME}" ] || [ -z "${PACKAGE_VERSION}" ]; then
  zz_log e "Failed to extract package name or version from package.json"
  exit 1
fi

zz_log i "Publishing ${PACKAGE_NAME}@${PACKAGE_VERSION} to ${REGISTRY_URL}"

# Authentication is handled by npm itself: with `id-token: write` on the job (npm 11.5.1+), `npm publish`
# requests the OIDC token for the registry and exchanges it for a short-lived publish token.
# Do not write an _authToken to .npmrc, it would take precedence over this exchange.
if [ -z "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" ] && [ "${DRY_RUN}" != "true" ]; then
  zz_log e "GitHub Actions OIDC not available. Ensure the job has id-token: write permission."
  exit 1
fi

# Build npm publish command
PUBLISH_CMD="npm publish --registry ${REGISTRY_URL}"

# Add tag if not "latest" (npm defaults to latest anyway, but be explicit for clarity)
if [ "${DIST_TAG}" != "latest" ]; then
  PUBLISH_CMD="${PUBLISH_CMD} --tag ${DIST_TAG}"
fi

# Add provenance flag if enabled and version supports it (npm 10.2.0+)
if [ "${PROVENANCE}" = "true" ]; then
  PUBLISH_CMD="${PUBLISH_CMD} --provenance"
fi

# Add dry-run flag if enabled
if [ "${DRY_RUN}" = "true" ]; then
  PUBLISH_CMD="${PUBLISH_CMD} --dry-run"
  zz_log i "Running in dry-run mode (no upload will occur)"
fi

# Execute publish
if eval "${PUBLISH_CMD}"; then
  zz_log i "Successfully published ${PACKAGE_NAME}@${PACKAGE_VERSION}"

  # Output metadata for downstream steps
  echo "version=${PACKAGE_VERSION}" >> "${GITHUB_OUTPUT}"
  echo "name=${PACKAGE_NAME}" >> "${GITHUB_OUTPUT}"
else
  zz_log e "Failed to publish package"
  exit 1
fi
