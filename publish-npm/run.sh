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
  echo "Error: node could not be found. Please install Node.js to run this action." >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "Error: npm could not be found. Please install npm to run this action." >&2
  exit 1
fi

# Navigate to package directory
if [ "${PACKAGE_PATH}" != "." ]; then
  cd "${PACKAGE_PATH}" || { echo "Error: Could not change to directory '${PACKAGE_PATH}'" >&2; exit 1; }
fi

# Validate package.json exists
if [ ! -f "package.json" ]; then
  echo "Error: package.json not found in '${PACKAGE_PATH}'" >&2
  exit 1
fi

# Extract package metadata using node (more reliable than jq for various shells)
PACKAGE_NAME=$(node -e "console.log(require('./package.json').name)")
PACKAGE_VERSION=$(node -e "console.log(require('./package.json').version)")

if [ -z "${PACKAGE_NAME}" ] || [ -z "${PACKAGE_VERSION}" ]; then
  echo "Error: Failed to extract package name or version from package.json" >&2
  exit 1
fi

echo "Publishing ${PACKAGE_NAME}@${PACKAGE_VERSION} to ${REGISTRY_URL}" >&2

# Request OIDC token from GitHub
# This uses the built-in support in GitHub Actions for requesting ID tokens
OIDC_TOKEN=$( \
  node -e "
    const https = require('https');
    const token_url = process.env.ACTIONS_ID_TOKEN_REQUEST_URL;
    const token_audience = process.env.ACTIONS_ID_TOKEN_REQUEST_AUDIENCE;

    if (!token_url || !token_audience) {
      console.error('Error: GitHub Actions OIDC not available. Ensure the job has id-token: write permission.');
      process.exit(1);
    }

    const req = https.request(token_url + '&audience=' + token_audience, {
      method: 'GET',
      headers: {
        'Authorization': 'Bearer ' + process.env.ACTIONS_RUNTIME_TOKEN,
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => { data += chunk; });
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (json.token) {
            console.log(json.token);
          } else {
            console.error('Error: No token in response');
            process.exit(1);
          }
        } catch (e) {
          console.error('Error: Failed to parse token response:', e.message);
          process.exit(1);
        }
      });
    });

    req.on('error', (e) => {
      console.error('Error: Failed to request OIDC token:', e.message);
      process.exit(1);
    });

    req.end();
  " \
)

if [ -z "${OIDC_TOKEN}" ]; then
  echo "Error: Failed to obtain OIDC token from GitHub Actions" >&2
  exit 1
fi

# Configure npm registry and OIDC auth token via a project-local .npmrc.
# `npm config set` runs the "config" command, which does not support
# workspaces and errors with ENOWORKSPACES when PACKAGE_PATH is a workspace
# member of a monorepo. Writing the .npmrc directly avoids that command.
{
  echo "registry=${REGISTRY_URL}"
  echo "//${REGISTRY_URL#https://}:_authToken=${OIDC_TOKEN}"
} >> .npmrc

# Build npm publish command
PUBLISH_CMD="npm publish"

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
  echo "Running in dry-run mode (no upload will occur)" >&2
fi

# Execute publish
if eval "${PUBLISH_CMD}"; then
  echo "Successfully published ${PACKAGE_NAME}@${PACKAGE_VERSION}" >&2

  # Output metadata for downstream steps
  echo "version=${PACKAGE_VERSION}" >> "${GITHUB_OUTPUT}"
  echo "name=${PACKAGE_NAME}" >> "${GITHUB_OUTPUT}"
else
  echo "Error: Failed to publish package" >&2
  exit 1
fi
