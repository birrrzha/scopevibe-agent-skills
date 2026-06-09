# ScopeVibe Agent Skills

Install once — then control ScopeVibe from any AI coding agent.

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/birrrzha/scopevibe-agent-skills/main/install.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/birrrzha/scopevibe-agent-skills
bash scopevibe-agent-skills/install.sh
```

The installer:
1. Installs `@open-pencil/mcp` globally
2. Registers a **macOS LaunchAgent** — the bridge starts automatically at login
3. Adds the MCP endpoint to `~/.claude.json` so Claude Code finds it

## Claude Code (plugin marketplace)

```
/plugin marketplace add birrrzha/scopevibe-agent-skills
/plugin install scopevibe@scopevibe
```

## After install

1. Open **ScopeVibe** and open a `.pen` document
2. Restart Claude Code (to pick up the new MCP server)
3. Start designing — Claude will use the `scopevibe` MCP tools automatically

## What the skill does

The `SKILL.md` gives Claude a concrete workflow for ScopeVibe:
- How to create UI with `render` (JSX → canvas)
- How to batch-update nodes efficiently
- Icon workflow: always `fetch_icons` first, then `insert_icon` (never placeholders)
- When to stop and tell the user the bridge isn't running

## Uninstall

```bash
bash agent-skills/uninstall.sh
```

## Manual bridge start (without LaunchAgent)

```bash
npx @open-pencil/mcp-http
# or if installed globally:
openpencil-mcp-http
```

Bridge runs on `http://127.0.0.1:7600`. Health check: `http://127.0.0.1:7600/health`

## Architecture

```
Claude Code
    │  MCP (HTTP)
    ▼
openpencil-mcp-http          ← LaunchAgent, always on
  :7600/mcp  ─────────────── MCP tools
  :7601 (WS) ─────────────── browser bridge
                  │
              ScopeVibe app
              (open .pen doc)
```
