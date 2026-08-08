<!-- @format -->

# Run PHP Deployer

Composite action that installs PHP Deployer, resolves the deploy target (branch/tag/environment) from the triggering GitHub event, and runs a `dep` command over SSH. Deployer's warnings/errors are reported as reviewdog check annotations.

## What It Does

- Sets up PHP/Composer, installs `deployer/deployer`, and adds it to `PATH`.
- Installs reviewdog via [`setup-reviewdog`](../setup-reviewdog/README.md).
- Installs the SSH key used to reach the deploy target.
- Resolves `--branch`/`--tag` and the environment from `github.event_name`/`github.ref` (PR review request → `unstable`, `release/*` → `staging`, `main` → `production`, tags with/without a `-` suffix → `staging`/`production`, anything else falls back to the current ref for `dep=deploy`).
- Runs `dep <command> ... -- <selector>`, replays its log, and pipes it through reviewdog (`-reporter=github-check`, best-effort) so warnings/exceptions surface as check annotations instead of being buried in the raw log.
- Extracts a `##KLICK_DEPLOY_URL##` marker from the log into the `deploy-url` output, when present.

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
