<!-- @format -->

# Run PHP Deployer

Composite action that installs PHP Deployer and runs a `dep` command over SSH. The deploy target (branch/tag/environment) is resolved by [`resolve-environment`](../resolve-environment/README.md) from the triggering GitHub event. Deployer's warnings/errors are reported as reviewdog check annotations.

## What It Does

- Sets up PHP/Composer via [`setup-php`](../setup-php/README.md), installs `deployer/deployer`, and adds it to `PATH`.
- Installs reviewdog via [`setup-reviewdog`](../setup-reviewdog/README.md).
- Installs the SSH key used to reach the deploy target.
- Resolves `--branch`/`--tag` and the environment via [`resolve-environment`](../resolve-environment/README.md).
- Runs `dep <command> ... -- <selector>`, replays its log, and pipes it through reviewdog (`-reporter=github-check`, best-effort) so warnings/exceptions surface as check annotations instead of being buried in the raw log.
- Extracts a `##KLICK_DEPLOY_URL##` marker from the log into the `deploy-url` output, when present.

## Inputs

### version

**Optional.** The version of Deployer to install. Defaults to the latest release.

### dep

**Required.** The deployer command to run. Defaults to `deploy`.

### options

**Optional.** Options to pass to the deployer command.

### selector

**Optional.** The selector to use for the deployer command. Defaults to `all`.

### environment

**Optional.** The environment to use for the deployer command. Defaults to the environment determined by [`resolve-environment`](../resolve-environment/README.md) from the triggering git branch/tag.

### branch-scope

**Optional.** Branch name identifying an isolated per-branch preview deployment, forwarded as `--branch-scope` to Deployer. Leave empty for a normal (non-preview) deployment.

### ssh-private-key

**Required.** SSH private key for deployment.

### known-hosts

**Required.** Known hosts for SSH.

### ssh-config

**Optional.** SSH configuration.

### github-token

**Required.** GitHub token for reviewdog reporting of Deployer warnings/errors as check annotations.

### reviewdog-version

**Optional.** The version of reviewdog to install. Defaults to `v0.20.3`.

## Outputs

- `deploy-url`: The deployed URL (`https://<alias>`), captured from the `##KLICK_DEPLOY_URL##` marker. Empty for non-deploy commands (unlock/teardown).

## Local Usage

Run this action locally using the root `npx @tomgrv/actions` dispatcher:

```sh
npx @tomgrv/actions run-deployer
```

Required environment variables must be set before running. See [Inputs](#inputs) for details.

## Usage

```yaml
- name: Run Deployer
  uses: tomgrv/actions/run-deployer
  with:
    dep: deploy
    selector: env=production
    ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
    known-hosts: ${{ secrets.KNOWN_HOSTS }}
    github-token: ${{ secrets.GITHUB_TOKEN }}
```
