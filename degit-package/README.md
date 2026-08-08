<!-- @format -->

# GitHub Action: Degit Package

This action imports the tip of a source repository branch into a target repository (or subdirectory), removes configured paths, and prepares a branch/workdir for `create-pr`.

## Inputs

### github-token

Required. GitHub token with access to source and target repositories.

### source-repository

Required. Source repository (`owner/name`) or GitHub URL.

### source-branch

Optional. Source branch to import. Defaults to source repository default branch.

### repository-organization

Required. GitHub organization or user that owns the origin repository.

### repository-name

Required. Name of the origin repository.

### target-subdir

Optional. Target subdirectory where content is imported. Default: `.`

### remove-paths

Optional. Comma-separated paths removed after import. Default: `.github,.devcontainer,.git`

### head-branch

Optional. Branch to prepare in target repository. Auto-generated when empty.

## Outputs

- `has-changes`
- `degit-branch`
- `degit-workdir`
- `source-branch`
- `source-sha`

## Usage

```yaml
- name: Degit package
  id: degit
  uses: tomgrv/actions/degit-package
  with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
      source-repository: ${{ github.repository }}
      source-branch: ${{ github.ref_name }}
      repository-organization: ${{ matrix.package.org }}
      repository-name: ${{ matrix.package.name }}
      target-subdir: .
      remove-paths: .github,.devcontainer,.git
```
