---
name: feature-ai-coding
description: AI coding skill pack (caveman terse-mode family + product-management workflow skills) plus the Claude Code GitHub Action for @claude mentions.
---

<!-- @format -->

# ai-coding

## Description

Use this feature when a repository wants a shared set of agent-agnostic coding skills, plus a GitHub Action that lets any contributor trigger Claude on an issue or pull request via an `@claude` mention.

## Commands

- `@claude <request>` in an issue comment, PR comment, PR review, or PR review comment — triggers the Claude Code GitHub Action.
- `/caveman`, `/caveman-commit`, `/caveman-review`, `/caveman-compress`, `/caveman-help` — terse-communication-mode skills.
- `/pm-research-synthesis`, `/pm-roadmap-brief`, `/pm-prd-draft`, `/pm-metrics-digest`, `/pm-release-notes` — product-management workflow skills.

## Use For

- Letting any AI coding agent that reads `.github/skills/` discover and use these skills.
- Giving maintainers a low-friction way to delegate issue/PR work to Claude via `@claude` mentions.

## Do Not Use For

- Repository-specific git workflow automation (use `githooks`/`gitutils`).
- Commit message conventions (use `commit-naming`).

## Agent Guidance

- Treat every `.github/skills/*/SKILL.md` file as an available skill regardless of which agent is running — none of them assume a specific agent's tool names.
- The `claude.yml` workflow requires an `ANTHROPIC_API_KEY` repository secret to function; do not assume it exists without checking.
- The `pm/*` skills are tool-agnostic: they read local files/folders or use the `gh` CLI by default, and only prefer an MCP connector (Notion, Linear, Drive, etc.) when one is already configured in the current session.
- The `claude.yml` workflow is event-triggered only (`issue_comment`, `pull_request_review_comment`, `issues`, `pull_request_review`) — each run is a fresh, short-lived job with no persistent session to wake up later. Do not add `send_later`/`ScheduleWakeup`-style self check-ins, cron polling, or any other delayed-callback hook to this workflow or to guidance for agents running it; react to the GitHub event that triggered the run and stop. If a PR needs ongoing follow-up, rely on further GitHub events (new comments, reviews, pushes) to re-trigger the workflow, not on scheduled wakeups.
- When a run acts on a PR review comment (fixes it, or deliberately skips it), reply on that comment's thread stating what was done or why it was skipped.
