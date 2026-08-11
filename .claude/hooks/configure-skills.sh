#!/bin/sh

# npx-skills wrapper for this feature. Single source of truth for turning
# ai-coding.json (repo root — the merged manifest of skills/agents/plugins
# from this feature and any other feature that dependsOn it and ships its
# own stubs/ai-coding.json fragment) into live state:
#   - skills installed into each declared agent's folder, via
#     `npx skills` (https://github.com/vercel-labs/skills)
#   - plugins declared in .claude/settings.json's enabledPlugins /
#     extraKnownMarketplaces (the "associated settings file" for Claude
#     Code plugins)
#
# Usage: configure-skills.sh [sync]   (sync is the default when no command given)
#
# Runs from two triggers:
#  - devcontainer postCreate, via configure-feature (see configure-skills.sh)
#  - Claude Code SessionStart hook, for claude.ai/code web/cloud sessions
#    (registered in .claude/settings.json), so cloud sessions stay in sync
#    with ai-coding.json too.

REGISTRY="./ai-coding.json"

if [ ! -f "$REGISTRY" ]; then
    echo "configure-skills.sh: $REGISTRY not found, skipping" >&2
    exit 0
fi

command="${1:-sync}"

if [ -n "$1" ]; then
    shift 1 
fi

echo "configure-skills.sh: running command '$command' with args '$@'" >&2

if ! command -v jq > /dev/null 2>&1; then
    echo "configure-skills.sh: jq not found, skipping" >&2
    exit 0
fi

sync_plugins() {

    # Read the plugins from ai-coding.json
    plugins=$(jq -c '.plugins // []' "$REGISTRY")
    if [ "$plugins" = "[]" ]; then
        return 0
    fi

    # Read the agents from the command line or from ai-coding.json, 
    agents="$@"
    if [ -z "$agents" ]; then
        agents="--agents "$(jq -r '.agents // [] | .[] ' "$REGISTRY")
    fi

    # Merge the plugins into .claude/settings.json's enabledPlugins and extraKnownMarketplaces
    merged=$(jq --argjson plugins "$plugins" '
        reduce $plugins[] as $p (.;
            .enabledPlugins[$p.marketplace + "@" + $p.name] = true
            | .extraKnownMarketplaces[$p.marketplace] = {"source": {"source": "git", "url": $p.url}}
        )' .claude/settings.json) || {
        echo "configure-skills.sh: failed to sync plugins into .claude/settings.json" >&2
        return 1
    }

    # Write the merged settings back to .claude/settings.json
    echo "configure-skills.sh: synced plugins into .claude/settings.json" >&2
    printf '%s\n' "$merged" >".claude/settings.json"

    # Install plugins via npx skills using url without .git, so they are available for Claude Code sessions
    for url in $(jq -r '.plugins // [] | .[] | .url' "$REGISTRY"); do
        echo "configure-skills.sh: installing plugin from $url" >&2
        npx --yes skills add -y "$url" --skills '*' ${agents:+$agents} || {
            echo "configure-skills.sh: failed to install plugin from $url" >&2
            return 1
        }
    done
   
}

case "$command" in
sync)
    sync_plugins "$@"
    ;;
*)
    npx --yes skills@latest $command "$@" || {
        echo "configure-skills.sh: failed to run 'npx skills $command'" >&2
        exit 1
    }
    ;;
esac
