# configure-ci

Detect the forge running the workflow and normalise it for the next steps.

```yaml
- id: ci
  uses: tomgrv/actions/configure-ci@v5
- if: ${{ steps.ci.outputs.forge == 'github' }}
  run: echo "GitHub only"
```

## Outputs

| Output       | Description                                            |
| ------------ | ------------------------------------------------------ |
| `forge`      | `github`, `forgejo` or `gitea`.                        |
| `server-domain` | Domain of the forge, host and port without scheme.   |
| `api-url`    | REST API URL of the forge (`github.api_url`).          |

## Side effects

- Exports `FORGE` (`github` or `forgejo`, the API family Gitea shares), `FORGE_FLAVOR` (`github`, `forgejo` or `gitea`) and `FORGE_DOMAIN` (the `server-domain` output) to the next steps.
- Off GitHub, puts a `gh` executable on `PATH` that translates the subcommands used by these actions to the forge's REST API ([`forge.sh`](forge.sh)). On GitHub the real `gh` is left alone.

Gitea is told from Forgejo by probing `/api/forgejo/v1/version`.

Event triggers, job-level `if`, `runs-on` and `uses:` resolution are evaluated before any step, so an action cannot normalise those: guard them with `github.server_url` in the workflow.
