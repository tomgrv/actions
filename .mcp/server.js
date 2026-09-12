#!/usr/bin/env node
/** @format */

// MCP server that teaches an agent how to use this repo's composite GitHub
// Actions: which actions exist, their full docs, and the exact `dispatch.sh`
// command to run one locally.
import { readFileSync, readdirSync, existsSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import { z } from 'zod'

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..')

function listActions() {
    return readdirSync(ROOT, { withFileTypes: true })
        .filter((e) => e.isDirectory())
        .map((e) => e.name)
        .filter((name) => existsSync(join(ROOT, name, 'action.yml')))
        .map((name) => {
            const yml = readFileSync(join(ROOT, name, 'action.yml'), 'utf8')
            const nameMatch = yml.match(/^name:\s*(.+)$/m)
            const descMatch = yml.match(/^description:\s*(.+)$/m)
            return {
                id: name,
                name: nameMatch ? nameMatch[1].trim() : name,
                description: descMatch ? descMatch[1].trim() : '',
                hasRunScript: existsSync(join(ROOT, name, 'run.sh')),
            }
        })
}

function actionReadme(action) {
    const path = join(ROOT, action, 'README.md')
    if (!existsSync(path)) throw new Error(`Unknown action: ${action}`)
    return readFileSync(path, 'utf8')
}

function actionYaml(action) {
    const path = join(ROOT, action, 'action.yml')
    if (!existsSync(path)) throw new Error(`Unknown action: ${action}`)
    return readFileSync(path, 'utf8')
}

function dispatchCommand({ action, args }) {
    const argsSuffix = args && args.length ? ` ${args.join(' ')}` : ''
    return `./dispatch.sh ${action}${argsSuffix}`
}

function usageSnippet({ action, ref }) {
    return `uses: tomgrv/actions/${action}@${ref ?? 'main'}`
}

const server = new McpServer({
    name: 'actions',
    version: '1.0.0',
})

server.registerTool(
    'list_actions',
    {
        title: 'List composite actions',
        description:
            'List every composite GitHub Action in this repo, with its display name and description.',
        inputSchema: {},
    },
    async () => ({
        content: [
            { type: 'text', text: JSON.stringify(listActions(), null, 2) },
        ],
    })
)

server.registerTool(
    'get_action_readme',
    {
        title: 'Get action README',
        description:
            "Fetch an action's full README (usage examples, inputs, outputs) so an agent can decide whether/how to use it.",
        inputSchema: {
            action: z.string().describe('Action id/directory, e.g. "check-lock"'),
        },
    },
    async ({ action }) => ({
        content: [{ type: 'text', text: actionReadme(action) }],
    })
)

server.registerTool(
    'get_action_yaml',
    {
        title: 'Get action.yml',
        description:
            "Fetch an action's raw action.yml (inputs/outputs/branding) for precise wiring into a workflow.",
        inputSchema: {
            action: z.string().describe('Action id/directory, e.g. "check-lock"'),
        },
    },
    async ({ action }) => ({
        content: [{ type: 'text', text: actionYaml(action) }],
    })
)

server.registerTool(
    'get_dispatch_command',
    {
        title: 'Get local dispatch command',
        description:
            'Return the exact dispatch.sh command to run an action locally from a clone of this repo, for actions that ship a run.sh.',
        inputSchema: {
            action: z.string().describe('Action id/directory, e.g. "check-lock"'),
            args: z
                .array(z.string())
                .optional()
                .describe('Extra arguments to pass through to dispatch.sh'),
        },
    },
    async ({ action, args }) => ({
        content: [{ type: 'text', text: dispatchCommand({ action, args }) }],
    })
)

server.registerTool(
    'get_usage_snippet',
    {
        title: 'Get workflow usage snippet',
        description:
            'Return the `uses:` line to reference this action from a consumer GitHub Actions workflow.',
        inputSchema: {
            action: z.string().describe('Action id/directory, e.g. "check-lock"'),
            ref: z
                .string()
                .optional()
                .describe('Git ref/tag to pin, e.g. "v2"; defaults to "main"'),
        },
    },
    async ({ action, ref }) => ({
        content: [{ type: 'text', text: usageSnippet({ action, ref }) }],
    })
)

const transport = new StdioServerTransport()
await server.connect(transport)
