<!-- @format -->

# `.agents/`

Single source of truth for every AI coding tool's configuration and guidance in this repo (Claude Code, GitHub Copilot, and any other agent that reads `.github/skills/`). Real files live here; every tool-specific conventional path is a symlink back into this directory.

**Always edit the file under `.agents/`, never a symlink.**

## Layout

| Path here        | Symlinked from                                      | Consumed by                                                               |
| ---------------- | --------------------------------------------------- | ------------------------------------------------------------------------- |
| `skills/<name>/` | `.github/skills/<name>` and `.claude/skills/<name>` | Copilot/agent-agnostic (`.github/`) · Claude Code Skill tool (`.claude/`) |

## Adding a new skill

1. Write the real `SKILL.md` (and any sibling files) under `.agents/skills/<name>/`.
2. Symlink from both conventional paths:
    ```sh
    ln -s ../../.agents/skills/<name> .github/skills/<name>
    ln -s ../../.agents/skills/<name> .claude/skills/<name>
    ```
3. `git add` all three — git tracks the symlink as mode `120000`, not a content copy.
