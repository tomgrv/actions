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
├── package.json        # Minimal private package for commitlint scope (required)
├── run.sh              # Main execution script (required for locally-runnable actions)
├── setup.sh            # Optional setup script
└── README.md           # Documentation (required)
```

### Per-Action package.json

Every action directory must have a minimal `package.json` with:
- `name`: the folder name (no `@org/` prefix)
- `private: true` — these packages are never published individually
- `description`: brief description matching `action.yml`

```json
{
    "name": "action-name",
    "private": true,
    "description": "Short description of what the action does."
}
```

This minimal file is used only to provide the workspace scope for `commitlint`.

Every package in this repository, including the root one, is `private: true` and is **never published to npm**. The npm workspace setup exists solely to manage the monorepo's own code and tooling (commitlint scopes, lint-staged, prettier, `npm-check-updates`, ...). Actions are consumed exclusively via `uses: tomgrv/actions/<action-name>@<ref>` in a workflow; `dispatch.sh` is a local, unpublished helper for running an action's `run.sh` directly from a clone of this repository (see below).

### Local Usage (dispatch.sh)

All actions with a `run.sh` can be invoked locally via the root `dispatch.sh`:

```sh
./dispatch.sh <action-name> [args...]
```

`dispatch.sh` automatically sets sensible defaults for all `GITHUB_*` environment variables. Users only need to supply `GITHUB_TOKEN` for actions that call the GitHub API.

Add a `## Local Usage` section to every action README:

```markdown
## Local Usage

Run this action locally using the root `./dispatch.sh` dispatcher:

\`\`\`sh
./dispatch.sh action-name
\`\`\`

Required environment variables must be set before running. See [Inputs](#inputs) for details.
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

# One-line description of what this script does.

set -eu

# Environment variable handling with defaults
REPOSITORY="${REPOSITORY:-${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}}"
PARAMETER="${PARAMETER:-default-value}"

# Setup problems (missing token/binary, bad input, defaulted values) are
# plain logs, not GitHub annotations - see "Logging conventions" below.
if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "Error: GITHUB_TOKEN is required" >&2
    exit 1
fi

# Export GitHub token for gh CLI
export GH_TOKEN="${GITHUB_TOKEN}"

# Safe directory handling (if needed)
if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    cd "${GITHUB_WORKSPACE}" || exit 1
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

# Main logic here. A notice is warranted because this is a fact about the
# analyzed repository (e.g. nothing matched the filter), not about setup.
echo "::notice::Nothing to process, target path is empty." >&2

# Output to GITHUB_OUTPUT
printf 'output-name=%s\n' "${value}"
```

**Key conventions:**

1. Use `#!/usr/bin/sh` shebang for portability
2. Start with a one-to-three line comment stating what the script does
3. Use `set -eu` (or `set -ef`/`set -e` when a `noglob`/pipefail comment explains the exception) to exit on errors and undefined variables
4. Use `${VAR:-default}` for optional variables with defaults
5. Use `${VAR:?error message}` for required variables
6. Send user messages to stderr (`>&2`)
7. Follow the **logging conventions** below for `::notice::`/`::warning::`/`::error::` vs. plain logs
8. Output variables using `printf` format
9. Make script executable: `chmod +x run.sh`
10. Use shellcheck disable comments when needed: `# shellcheck disable=SC2086`

### Logging Conventions

GitHub workflow-command annotations (`::notice::`, `::warning::`, `::error::`) surface directly on the PR/checks UI of the **repository the action runs against**. Reserve them for facts about that repository - the thing being analyzed or acted upon - not for this toolkit's own setup:

- **Setup/config points stay in plain logs** (`echo "..." >&2`, prefixed `Error:` when fatal): missing `GITHUB_TOKEN`/`REVIEWDOG_GITHUB_API_TOKEN`, a required CLI tool not found (`jq`, `gh`, `composer`, `npm`, `reviewdog`, the linter binary, ...), an input left at its default (`"PATHS not set, using default: app"`), or a bad/missing config file path. These are exactly as actionable printed in the job log as they would be as an annotation, but they are not something about the analyzed repository's code, so they must not be tagged `::error::`/`::warning::`/`::notice::`. Still `exit 1` when fatal - only the annotation is dropped, not the failure.
- **`::notice::` for facts about the analyzed repository**: no files matched the target path/filter, a target directory or manifest is absent, nothing changed, a PR is already up to date. Example: "no PHP files to analyze" is a notice; "the `phpstan` binary is missing" is a plain log.
- **`::warning::`/`::error::` for the analysis outcome itself**: this is usually produced by the wrapped tool via reviewdog (checkstyle/sarif/rdjson piped through `reviewdog`), not by an `echo` in `run.sh`. Where `run.sh` does emit one directly (e.g. a test suite failing, a PR title failing commitlint), it must be reporting the actual result of checking the target, not a wrapper-script problem.

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

### Reviewdog-Based Actions

Actions that report findings via reviewdog must follow this pattern:

#### Standard inputs (add to every reviewdog action)

```yaml
inputs:
    name:
        description: Name reported by reviewdog to identify this check.
        required: false
        default: tool-name # defaults to the tool/check this action wraps
    level:
        description: 'Report level for reviewdog [info,warning,error].'
        required: false
        default: error
    reporter:
        description: 'Reporter of reviewdog command [github-pr-check,github-check,github-pr-review].'
        required: false
        default: github-pr-check
    filter-mode:
        description: 'Filtering mode for the reviewdog command [added,diff_context,file,nofilter].'
        required: false
        default: added
    fail-level:
        description: 'Exit code for reviewdog if it finds at least the specified level of diagnostic [none,any,info,warning,error].'
        required: false
        default: none
    reviewdog-flags:
        description: Additional reviewdog flags.
        required: false
        default: ''
```

#### Map inputs to env vars in action.yml

```yaml
env:
    REVIEWDOG_GITHUB_API_TOKEN: ${{ inputs.github-token }}
    REVIEWDOG_NAME: ${{ inputs.name }}
    REVIEWDOG_REPORTER: ${{ inputs.reporter }}
    REVIEWDOG_LEVEL: ${{ inputs.level }}
    REVIEWDOG_FILTER_MODE: ${{ inputs.filter-mode }}
    REVIEWDOG_FAIL_LEVEL: ${{ inputs.fail-level }}
    REVIEWDOG_FLAGS: ${{ inputs.reviewdog-flags }}
```

#### Script pattern for reviewdog

```sh
REVIEWDOG_NAME="${REVIEWDOG_NAME:-tool-name}"
REVIEWDOG_REPORTER="${REVIEWDOG_REPORTER:-github-pr-check}"
REVIEWDOG_LEVEL="${REVIEWDOG_LEVEL:-error}"
REVIEWDOG_FILTER_MODE="${REVIEWDOG_FILTER_MODE:-added}"
REVIEWDOG_FAIL_LEVEL="${REVIEWDOG_FAIL_LEVEL:-none}"
REVIEWDOG_FLAGS="${REVIEWDOG_FLAGS:-}"

# All informational messages go to stderr
echo "Running analysis..." >&2

# Capture reviewdog exit code; do NOT swallow it
exit_code=0
# shellcheck disable=SC2086
tool_command | \
  reviewdog \
    -f=FORMAT \
    -name="${REVIEWDOG_NAME}" \
    -reporter="${REVIEWDOG_REPORTER}" \
    -level="${REVIEWDOG_LEVEL}" \
    -filter-mode="${REVIEWDOG_FILTER_MODE}" \
    -fail-level="${REVIEWDOG_FAIL_LEVEL}" \
    ${REVIEWDOG_FLAGS} || exit_code=$?

# GITHUB_OUTPUT lines go to stdout (redirected to $GITHUB_OUTPUT in action.yml)
printf 'has-changes=false\n'
exit $exit_code
```

**Key rules:**
- Pipe tool output **only** to reviewdog or to stderr (`>&2`). Never mix with stdout.
- All stdout lines must be `key=value` pairs written to `$GITHUB_OUTPUT`.
- Use `exit_code=0; cmd || exit_code=$?` to capture reviewdog's exit code.
- Propagate the exit code: `exit $exit_code`.

#### Fix-mode pattern (phpstan, pint, phpinsights)

```sh
if [ "${FIX}" = "true" ]; then
  # Run tool in fix mode; all output goes to stderr
  tool --fix ... >&2 || true
  # Check for changes via git diff
  if git diff --quiet; then
    printf 'has-changes=false\n'
  else
    printf 'has-changes=true\n'
  fi
else
  # Normal reviewdog review mode
  exit_code=0
  tool ... 2>/dev/null | reviewdog ... || exit_code=$?
  printf 'has-changes=false\n'
  exit $exit_code
fi
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
# Check if jq is available (setup concern: plain log, see "Logging conventions")
if ! command -v jq > /dev/null 2>&1; then
    echo "Error: jq is required" >&2
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
