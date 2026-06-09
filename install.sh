#!/usr/bin/env bash
# ScopeVibe MCP bridge installer
# Installs the bridge server as a macOS LaunchAgent (auto-starts at login)
# and wires up the MCP endpoint in Claude Code.

set -euo pipefail

LABEL="net.scopevibe.mcp-bridge"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
MCP_HTTP_PORT="${MCP_HTTP_PORT:-7600}"
MCP_WS_PORT="${MCP_WS_PORT:-7601}"
CLAUDE_CONFIG="$HOME/.claude.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

info()    { echo -e "  ${GREEN}✓${NC} $*"; }
warn()    { echo -e "  ${YELLOW}!${NC} $*"; }
error()   { echo -e "  ${RED}✗${NC} $*" >&2; }
section() { echo -e "\n${YELLOW}▸ $*${NC}"; }

# ── 1. Resolve runtime ────────────────────────────────────────────────────────

section "Resolving runtime"

NODE_BIN=""
for candidate in "$(which node 2>/dev/null)" "$(which bun 2>/dev/null)"; do
  if [[ -x "$candidate" ]]; then NODE_BIN="$candidate"; break; fi
done

if [[ -z "$NODE_BIN" ]]; then
  error "Neither node nor bun found. Install one of them first."
  exit 1
fi
info "Runtime: $NODE_BIN"

# ── 2. Install @open-pencil/mcp globally ─────────────────────────────────────

section "Installing @open-pencil/mcp"

if command -v bun &>/dev/null; then
  bun add -g @open-pencil/mcp 2>&1 | tail -2
  BRIDGE_BIN="$(bun pm bin -g)/openpencil-mcp-http"
elif command -v npm &>/dev/null; then
  npm install -g @open-pencil/mcp --quiet
  BRIDGE_BIN="$(npm bin -g)/openpencil-mcp-http"
else
  error "Neither bun nor npm found."
  exit 1
fi

if [[ ! -x "$BRIDGE_BIN" ]]; then
  error "openpencil-mcp-http not found at $BRIDGE_BIN after install."
  exit 1
fi
info "Bridge binary: $BRIDGE_BIN"

# ── 3. LaunchAgent (macOS auto-start) ─────────────────────────────────────────

section "Installing macOS LaunchAgent"

# Unload existing agent if present
if launchctl list "$LABEL" &>/dev/null 2>&1; then
  launchctl unload "$PLIST" 2>/dev/null || true
  warn "Replaced existing LaunchAgent"
fi

mkdir -p "$HOME/Library/LaunchAgents"
mkdir -p "$HOME/Library/Logs/ScopeVibe"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${BRIDGE_BIN}</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PORT</key>
    <string>${MCP_HTTP_PORT}</string>
    <key>WS_PORT</key>
    <string>${MCP_WS_PORT}</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${HOME}/Library/Logs/ScopeVibe/mcp-bridge.log</string>
  <key>StandardErrorPath</key>
  <string>${HOME}/Library/Logs/ScopeVibe/mcp-bridge.log</string>
  <key>ThrottleInterval</key>
  <integer>5</integer>
</dict>
</plist>
EOF

launchctl load "$PLIST"
info "LaunchAgent loaded — bridge will start now and on every login"

# ── 4. Wait for bridge to be ready ───────────────────────────────────────────

section "Waiting for bridge"

RETRIES=10
for ((i=1; i<=RETRIES; i++)); do
  STATUS=$(curl -sf "http://127.0.0.1:${MCP_HTTP_PORT}/health" 2>/dev/null || echo "")
  if [[ -n "$STATUS" ]]; then
    info "Bridge is up: $STATUS"
    break
  fi
  if [[ $i -eq $RETRIES ]]; then
    warn "Bridge didn't respond in time — it may still be starting"
    warn "Check logs: tail -f ~/Library/Logs/ScopeVibe/mcp-bridge.log"
  fi
  sleep 1
done

# ── 5. Wire up Claude Code MCP config ─────────────────────────────────────────

section "Configuring Claude Code"

MCP_ENTRY=$(cat <<'JSON'
{
  "type": "http",
  "url": "http://127.0.0.1:7600/mcp"
}
JSON
)
MCP_ENTRY="${MCP_ENTRY/7600/$MCP_HTTP_PORT}"

if [[ -f "$CLAUDE_CONFIG" ]]; then
  # Use python3 (always on macOS) to merge config safely
  python3 - "$CLAUDE_CONFIG" "$MCP_ENTRY" <<'PY'
import json, sys

config_path = sys.argv[1]
entry = json.loads(sys.argv[2])

with open(config_path) as f:
    cfg = json.load(f)

cfg.setdefault("mcpServers", {})
cfg["mcpServers"]["scopevibe"] = entry

with open(config_path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
PY
  info "Added 'scopevibe' to mcpServers in $CLAUDE_CONFIG"
else
  python3 - "$CLAUDE_CONFIG" "$MCP_ENTRY" <<'PY'
import json, sys

config_path = sys.argv[1]
entry = json.loads(sys.argv[2])

cfg = {"mcpServers": {"scopevibe": entry}}

with open(config_path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
PY
  info "Created $CLAUDE_CONFIG with MCP config"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}ScopeVibe bridge installed.${NC}"
echo ""
echo "  MCP endpoint : http://127.0.0.1:${MCP_HTTP_PORT}/mcp"
echo "  Health check : http://127.0.0.1:${MCP_HTTP_PORT}/health"
echo "  Logs         : ~/Library/Logs/ScopeVibe/mcp-bridge.log"
echo ""
echo "Next steps:"
echo "  1. Open ScopeVibe and open a .pen document"
echo "  2. Restart Claude Code (so it picks up the new MCP server)"
echo "  3. Start designing!"
echo ""
echo "Uninstall: bash $(dirname "$0")/uninstall.sh"
