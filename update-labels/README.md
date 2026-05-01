<!-- @format -->

# GitHub Action: Update Repository Labels

This action creates or updates GitHub repository labels from a JSON file (Hyouji format) or a comma-separated list. The action is idempotent and performs seamless updates without intermediate deletion.

## Features

- **Flexible input**: Use a JSON file (`.github/labels.json`) or a comma-separated list
- **Idempotent**: Safe to run multiple times without side effects
- **Seamless updates**: Labels are updated in place without deletion and recreation
- **Auto-deletion**: When using a JSON file, labels not in the file are deleted from the repository
- **Smart color generation**: Automatic color assignment based on priority numbers

## Inputs

### github-token

**Required.** GitHub token with repository permissions.

### repository

**Optional.** Repository in the format `owner/name`. Defaults to the current repository.

### labels-file

**Optional.** Path to labels.json file in Hyouji format. Defaults to `.github/labels.json` if it exists.

The Hyouji format is a JSON array of label objects:

```json
[
  {
    "name": "bug",
    "color": "d73a4a",
    "description": "Something isn't working"
  },
  {
    "name": "documentation",
    "color": "0075ca",
    "description": "Improvements or additions to documentation"
  }
]
```

### labels

**Optional.** Comma-separated list of label names with optional priority numbers (e.g., `"25 documentation,10 must,20 should"`). Used when `labels-file` does not exist.

Default: `25 documentation,10 must,20 should,30 could,80 duplicate,90 wont`

**Format:** Each label can be specified as:
- `<number> <name>`: Number prefix for priority-based color assignment (e.g., `10 must`)
- `<name>`: Simple name without number (uses default color)

**Color mapping by number:**
- 0-19: Red (high priority)
- 20-39: Blue (medium priority)
- 40-59: Cyan (lower priority)
- 60-79: Purple (could/nice-to-have)
- 80+: Gray (duplicate/won't fix)

## Outputs

- `labels-created`: Number of labels created.
- `labels-updated`: Number of labels updated.
- `labels-deleted`: Number of labels deleted (only when using JSON file).

## Usage

### With JSON file

Create a `.github/labels.json` file in your repository:

```json
[
  {"name": "bug", "color": "d73a4a", "description": "Something isn't working"},
  {"name": "enhancement", "color": "a2eeef", "description": "New feature or request"},
  {"name": "documentation", "color": "0075ca", "description": "Documentation updates"}
]
```

Then use the action:

```yaml
- name: Update labels from JSON
  uses: tomgrv/actions/update-labels
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

### With comma-separated list

```yaml
- name: Update labels from list
  uses: tomgrv/actions/update-labels
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
      labels: '10 critical,20 high,30 medium,40 low,80 duplicate,90 wont-fix'
```

### With custom repository

```yaml
- name: Update labels in another repo
  uses: tomgrv/actions/update-labels
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
      repository: owner/repo-name
      labels: '25 documentation,10 must,20 should,30 could'
```

## Behavior

### When using JSON file
- Labels in the file are created or updated in the repository
- Labels not in the file but present in the repository are deleted
- Label updates are seamless (no deletion and recreation)

### When using comma-separated list
- Labels in the list are created or updated in the repository
- Existing labels not in the list are **not** deleted (safe mode)
- Label updates are seamless (no deletion and recreation)

### Idempotency
Running the action multiple times with the same input produces the same result without unnecessary API calls or changes.
