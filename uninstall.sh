#!/usr/bin/env bash
# Remove the ScopeVibe MCP bridge LaunchAgent and Claude Code MCP entry

set -euo pipefail

LABEL="net.scopevibe.mcp-bridge"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
CLAUDE_CONFIG="$HOME/.claude.json"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "  ${GREEN}✓${NC} $*"; }
warn() { echo -e "  ${YELLOW}!${NC} $*"; }

if launchctl list "$LABEL" &>/dev/null 2>&1; then
  launchctl unload "$PLIST" 2>/dev/null || true
  info "LaunchAgent stopped"
fi

if [[ -f "$PLIST" ]]; then
  rm "$PLIST"
  info "Removed $PLIST"
fi

if [[ -f "$CLAUDE_CONFIG" ]]; then
  python3 - "$CLAUDE_CONFIG" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f:
    cfg = json.load(f)
cfg.get("mcpServers", {}).pop("scopevibe", None)
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
PY
  info "Removed 'scopevibe' from $CLAUDE_CONFIG"
fi

echo -e "\n${GREEN}ScopeVibe bridge uninstalled.${NC}"
