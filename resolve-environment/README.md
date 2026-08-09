<!-- @format -->

# GitHub Action: Resolve Deploy Environment

Resolves the deploy `branch`/`tag`/`environment` from the triggering GitHub event: PR review request → `unstable`, `release/*` branch → `staging`, `main` → `production`, a tag containing `-` → `staging`, any other tag → `production`. For any other branch push, or a `workflow_dispatch` run with `dep=deploy`, falls back to the current branch ref with no environment guess.

Used by [`run-deployer`](../run-deployer/README.md) to determine what to check out and which environment to target, without inlining trigger-inspection logic in that action.

## Inputs

### dep

**Optional.** The deployer command being run. Defaults to `deploy`. When set to anything else, the "any other branch push" fallback rule is skipped — commands like `unlock` or `teardown` are expected to receive an explicit `selector`/`environment` instead.

## Outputs

- `branch`: Resolved `--branch` value for Deployer, if any.
- `tag`: Resolved `--tag` value for Deployer, if any.
- `environment`: Resolved environment name (`unstable`/`staging`/`production`), if any.

## Local Usage

Run this action locally using the root `./dispatch.sh` dispatcher:

```sh
./dispatch.sh resolve-environment
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

## Example

```yaml
- name: Resolve deploy target
  id: target
  uses: tomgrv/actions/resolve-environment@v0
  with:
    dep: deploy

- name: Run Deployer
  uses: tomgrv/actions/run-deployer@v0
  with:
    dep: deploy
    ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
    known-hosts: ${{ secrets.KNOWN_HOSTS }}
    github-token: ${{ secrets.GITHUB_TOKEN }}
    environment: ${{ steps.target.outputs.environment }}
```
