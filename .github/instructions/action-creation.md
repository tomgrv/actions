---
description: 'Guidelines for creating new GitHub Actions in this repository. Follow these conventions for consistency.'
---

<!-- @format -->

## Creating New GitHub Actions

This guide explains how to create new GitHub composite actions in this repository following established conventions.

### Directory Structure

Each action should have its own directory with the following files:

```
action-name/
├── action.yml          # Action definition (required)
├── run.sh              # Main execution script (required)
├── setup.sh            # Optional setup script
└── README.md           # Documentation (required)
```

### Action Definition (action.yml)

```yaml
# @format

# @package tomgrv/actions/action-name

name: Action Display Name
description: Short description of what the action does
author: Perspikapps
branding:
    icon: icon-name # GitHub icon (e.g., check-circle, git-merge, tag)
    color: color-name # Branding color (blue, green, red, purple)

inputs:
    github-token:
        description: GitHub token with required permissions.
        required: true
    parameter-name:
        description: What this parameter does
        required: true/false
        default: 'default-value' # Optional default

outputs:
    output-name:
        description: What this output contains
        value: ${{ steps.step-id.outputs.output-var }}

runs:
    using: composite
    steps:
        - name: Step name
          id: step-id
          shell: sh
          env:
              ENV_VAR: ${{ inputs.parameter-name }}
              GITHUB_TOKEN: ${{ inputs.github-token }}
          run: sh -c "${{ github.action_path }}/run.sh" >> "$GITHUB_OUTPUT"
```

### Shell Script (run.sh)

```bash
#!/usr/bin/sh

set -eu

# Environment variable handling with defaults
REPOSITORY="${REPOSITORY:-${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}}"
PARAMETER="${PARAMETER:-default-value}"

# Validate required inputs
if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "::error::GITHUB_TOKEN is required" >&2
    exit 1
fi

# Export GitHub token for gh CLI
export GH_TOKEN="${GITHUB_TOKEN}"

# Safe directory handling (if needed)
if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

# Main logic here
echo "::notice::Processing..." >&2

# Output to GITHUB_OUTPUT
printf 'output-name=%s\n' "${value}"
```

**Key conventions:**

1. Use `#!/usr/bin/sh` shebang for portability
2. Use `set -eu` to exit on errors and undefined variables
3. Use `${VAR:-default}` for optional variables with defaults
4. Use `${VAR:?error message}` for required variables
5. Send user messages to stderr (`>&2`)
6. Use GitHub annotations: `::notice::`, `::warning::`, `::error::`
7. Output variables using `printf` format
8. Make script executable: `chmod +x run.sh`
9. Use shellcheck disable comments when needed: `# shellcheck disable=SC2086`

### Documentation (README.md)

```markdown
<!-- @format -->

# GitHub Action: Action Name

Brief description of what the action does.

## Inputs

### parameter-name

**Required/Optional.** Description of parameter.

## Outputs

- `output-name`: Description of output

## Usage

\`\`\`yaml

- name: Action display name
  uses: tomgrv/actions/action-name
  with:
  github-token: ${{ secrets.GITHUB_TOKEN }}
  parameter-name: value
  \`\`\`

## Behavior

Describe how the action behaves, including:

- What it does when run
- How it handles edge cases
- Whether it's idempotent
```

### Common Patterns

#### Working with GitHub CLI

```bash
export GH_TOKEN="${GITHUB_TOKEN}"

# List items
gh pr list --repo "${REPOSITORY}" --json number,title

# Get details
gh pr view "${PR_NUMBER}" --repo "${REPOSITORY}" --json url --jq '.url'

# Create or update
gh label create "${NAME}" --color "${COLOR}" --force
```

#### Working with JSON (using jq)

```bash
# Check if jq is available
if ! command -v jq > /dev/null 2>&1; then
    echo "::error::jq is required" >&2
    exit 1
fi

# Parse JSON
ITEMS=$(jq -r '.[] | "\(.name)|\(.value)"' "${FILE}")
```

#### Counting operations (avoiding subshell issues)

```bash
# Create temp directory
TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT

# Track operations in files
CREATED_FILE="${TMP_DIR}/created"
: > "${CREATED_FILE}"

# Increment counter
echo "1" >> "${CREATED_FILE}"

# Count at the end
CREATED=$(wc -l < "${CREATED_FILE}" | tr -d ' ')
```

### Updating Root README

After creating a new action, add it to the appropriate section in the root `README.md`:

```markdown
### Category Name

- [**action-name**](action-name/README.md): Brief description
```

### Testing

Before committing:

1. Test the action locally using a test workflow
2. Verify all outputs are correct
3. Check error handling
4. Ensure idempotency (can run multiple times safely)
5. Format code with prettier: `npm run format`

### Example Actions

Reference existing actions for patterns:

- **create-pr**: Complex workflow with git operations
- **update-labels**: JSON parsing and GitHub API usage
- **list-packages**: JQ and monorepo handling
- **config-bot**: Simple configuration action
