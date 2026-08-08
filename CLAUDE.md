<!-- @format -->

# AI Coding

This repo has the `ai-coding` devcontainer feature installed. Read `.agents/README.md` for the AI tooling layout.

## Skills — use them

All skills live under `.agents/skills/` (symlinked into `.github/skills/` for agent-agnostic agents and `.claude/skills/` for Claude Code's Skill tool). They are auto-discoverable — invoke them proactively per their descriptions.

Key skills:

- **`caveman`** / `caveman-commit` / `caveman-compress` / `caveman-help` / `caveman-review` — ultra-compressed terse communication mode and related utilities.
- **`pm/*`** (`pm-research-synthesis`, `pm-roadmap-brief`, `pm-prd-draft`, `pm-metrics-digest`, `pm-release-notes`) — product-management workflow skills.
- **`feature-ai-coding`** — this feature's own self-doc skill.

## GitHub Action — `@claude`

The `claude.yml` workflow responds to `@claude` mentions in issue/PR comments, PR reviews, and new issues. Requires a repository secret `ANTHROPIC_API_KEY`.

## Minimal Changes Discipline

Change only what the task requires. Don't touch unrelated config files or dependencies unless explicitly asked.
