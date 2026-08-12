<!-- @format -->

# GitHub Action: Publish NPM Package

Publishes a package to the npm registry using [GitHub's OIDC trusted publishers](https://docs.npmjs.com/trusted-publishers) integration. This eliminates the need to store npm tokens as GitHub secrets by using OpenID Connect (OIDC) tokens issued by GitHub Actions for authentication.

## Prerequisites

### 1. Configure npm Registry as a Trusted Publisher

Before using this action, configure the npm registry to trust GitHub Actions as a publisher for your package:

**On npmjs.com:**
1. Log in to your npm account at https://www.npmjs.com/settings/~profile
2. Go to the **Publishing** tab in your profile settings
3. Click **Configure Trusted Publishers**
4. Add a new trusted publisher:
   - **Where to publish:** npm registry
   - **Repository name:** `<owner>/<repo>` (e.g., `tomgrv/actions`)
   - **Repository owner:** Your GitHub username or organization
   - **Workflow filename:** The GitHub Actions workflow file using this action (e.g., `release.yml`)
   - **Environment name:** (optional) Leave blank unless you use GitHub Environments

See [npm's trusted publishers documentation](https://docs.npmjs.com/trusted-publishers) for detailed setup instructions.

### 2. Job Permissions

The job running this action must have `id-token: write` permission to request OIDC tokens from GitHub:

```yaml
permissions:
  id-token: write
  contents: read
```

## Inputs

### path

**Optional.** Path to the package directory containing `package.json`. Defaults to `'.'` (current directory).

```yaml
with:
  path: './packages/my-package'
```

### registry-url

**Optional.** npm registry URL. Defaults to `'https://registry.npmjs.org/'`.

Use this to publish to a private registry or alternative npm registry:

```yaml
with:
  registry-url: 'https://npm.example.com/'
```

### provenance

**Optional.** Generate provenance attestation for the package (npm 10.2.0+, Node 18.20.0+). Defaults to `'true'`.

Provenance attestations allow consumers to verify the package was built by your CI/CD system. Requires npm 10.2.0 or later.

```yaml
with:
  provenance: 'false'  # Disable if using older npm versions
```

### tag

**Optional.** Distribution tag to publish as (e.g., `latest`, `next`, `rc`). Defaults to `'latest'`.

Use this for pre-release versions or different release channels:

```yaml
with:
  tag: 'next'  # Publish as latest-next release, not stable
```

### dry-run

**Optional.** If `'true'`, runs publish in dry-run mode to validate the package without uploading. Defaults to `'false'`.

Useful for testing the publish process:

```yaml
with:
  dry-run: 'true'
```

## Outputs

### version

The published package version (extracted from `package.json`).

```yaml
- name: Check published version
  run: echo "Published version: ${{ steps.publish.outputs.version }}"
```

### name

The published package name (extracted from `package.json`).

```yaml
- name: Check published name
  run: echo "Published package: ${{ steps.publish.outputs.name }}"
```

## Works well with

- [**setup-node**](../setup-node/README.md) — included automatically to set up Node.js and npm.

## Workflow Example

### Basic publish to npm registry

```yaml
name: Publish to npm

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Publish package
        uses: tomgrv/actions/publish-npm@v1

      - name: Announce publication
        run: echo "Published ${{ steps.publish.outputs.name }}@${{ steps.publish.outputs.version }}"
```

### Publish from monorepo package

```yaml
- name: Publish from packages/ui
  uses: tomgrv/actions/publish-npm@v1
  with:
    path: './packages/ui'
```

### Pre-release to npm with custom tag

```yaml
- name: Publish next version
  uses: tomgrv/actions/publish-npm@v1
  with:
    tag: 'next'
    provenance: 'true'
```

### Test publish with dry-run

```yaml
- name: Validate publish configuration
  uses: tomgrv/actions/publish-npm@v1
  with:
    dry-run: 'true'
```

## Troubleshooting

### "GitHub Actions OIDC not available"

**Cause:** The job doesn't have `id-token: write` permission.

**Solution:** Add to your job:

```yaml
permissions:
  id-token: write
  contents: read
```

### "Package name or version not found"

**Cause:** `package.json` is missing required fields.

**Solution:** Ensure your `package.json` has both `name` and `version` fields:

```json
{
  "name": "my-package",
  "version": "1.0.0"
}
```

### "Trusted publisher not configured"

**Cause:** This workflow is not configured as a trusted publisher in npm.

**Solution:** Set up trusted publishing in your npm account settings as described in [Prerequisites](#prerequisites).

### Provenance attestation fails

**Cause:** npm version is too old (requires 10.2.0+) or Node.js version is too old (requires 18.20.0+).

**Solution:** Either upgrade npm/Node.js or disable provenance:

```yaml
with:
  provenance: 'false'
```

## Local Usage

Run this action locally using the root `./dispatch.sh` dispatcher:

```sh
./dispatch.sh publish-npm
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

Note: Local execution requires GitHub Actions OIDC setup, which is not available in local environments. Use dry-run mode to test the validation logic without a real npm token.

## Implementation Details

This action:

1. Validates that Node.js and npm are available
2. Locates and validates `package.json` in the specified path
3. Extracts package name and version metadata
4. Requests an OIDC token from GitHub Actions using the Action's built-in `ACTIONS_ID_TOKEN_REQUEST_URL` and `ACTIONS_RUNTIME_TOKEN`
5. Configures npm to use the OIDC token for authentication
6. Publishes the package with appropriate flags (provenance, tag, dry-run)
7. Outputs package metadata for downstream steps

The OIDC token is automatically exchanged by the npm registry for a short-lived publish token, so no long-lived secrets are needed.
