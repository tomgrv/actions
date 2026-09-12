<!-- @format -->

# actions MCP server

MCP server that lets an agent query this repo directly to discover and wire up its composite GitHub Actions — no need to read `README.md` or crawl the repo by hand.

Root `.mcp.json` wires it for Claude Code auto-load on session start.

## Tools

| Tool                   | Use it to...                                                            |
| ---------------------- | ------------------------------------------------------------------------ |
| `list_actions`         | Get every action id + name + description (check-lock, create-pr, ...).  |
| `get_action_readme`    | Read one action's full docs (usage, inputs, outputs) before wiring it.  |
| `get_action_yaml`      | Read an action's raw `action.yml` for precise input/output names.       |
| `get_dispatch_command` | Get the exact `dispatch.sh` command to run an action locally.           |
| `get_usage_snippet`    | Get the `uses:` line to reference the action from a consumer workflow.  |

## Run it

```sh
node .mcp/server.js
```

## Wire it into an agent

```json
{
    "mcpServers": {
        "actions": {
            "command": "node",
            "args": [".mcp/server.js"],
            "cwd": "/path/to/actions"
        }
    }
}
```

Point the agent's MCP config (`.vscode/mcp.json`, Claude Desktop/Code config, etc.) at a local clone of this repo, then ask it to wire an action into a workflow: it calls `list_actions` to see what's available, `get_action_readme`/`get_action_yaml` to check inputs, and `get_usage_snippet` for the exact `uses:` line to drop in.
