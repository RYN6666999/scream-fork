#!/bin/bash
# agentos.sh — AgentOS Runtime
# 從 shell/curl 呼叫 AgentOS 的同步端點。
# 升級：自動偵測本機工具 + 產生 runtime.json
#
# 用法:
#   ./agentos.sh init                    # 偵測工具 + 產生 runtime.json
#   ./agentos.sh run "task description"  # 同步執行（自動路由工具）
#   ./agentos.sh brain read <key>
#   ./agentos.sh brain write <key> <val>
#   ./agentos.sh brain search <query>
#   ./agentos.sh tools                   # 列出已發現的工具
#   ./agentos.sh health                  # 檢查所有工具狀態
#   ./agentos.sh up                      # 啟動 server
#   ./agentos.sh down                    # 停止

set -euo pipefail

BASE="${AGENTOS_URL:-http://localhost:8000}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTOS_DIR="${SCRIPT_DIR}/.."
RUNTIME_FILE="${AGENTOS_DIR}/agentos.json"

usage() {
    cat <<EOF
用法: $(basename "$0") <command> [args...]

Runtime 指令:
  init             偵測本機工具 + 產生 agentos.json
  tools            列出已發現的工具
  health           檢查所有工具連線狀態

AgentOS 指令:
  up               啟動 server（沒跑就起）
  down             停止
  run <task>       同步執行任務（自動路由工具）
  brain read <k>   讀腦庫
  brain write <k> <v>  寫腦庫
  brain search <q> 搜尋腦庫
EOF
}

# ── Tool Discovery ────────────────────────────────────────

detect_tools() {
  local tools="{}"

  # codebase-memory-mcp
  if command -v codebase-memory-mcp &>/dev/null; then
    local cbm_ver
    cbm_ver=$(codebase-memory-mcp --version 2>/dev/null | head -1)
    tools=$(echo "$tools" | jq --arg v "$cbm_ver" '. + {"codebase-memory-mcp": {"status": "installed", "version": $v, "capabilities": ["code-graph", "search", "architecture", "trace"]}}' 2>/dev/null || echo "$tools")
  fi

  # OpenCLI
  if command -v opencli &>/dev/null; then
    local oc_ver
    oc_ver=$(opencli --version 2>/dev/null | head -1)
    tools=$(echo "$tools" | jq --arg v "$oc_ver" '. + {"opencli": {"status": "installed", "version": $v, "capabilities": ["browser", "100+-sites"]}}' 2>/dev/null || echo "$tools")
  fi

  # agentsview
  if command -v agentsview &>/dev/null; then
    local av_ver
    av_ver=$(agentsview --version 2>/dev/null | head -1)
    tools=$(echo "$tools" | jq --arg v "$av_ver" '. + {"agentsview": {"status": "installed", "version": $v, "capabilities": ["session-analytics", "token-tracking"]}}' 2>/dev/null || echo "$tools")
  fi

  # headroom (Python package)
  if python3 -c "import headroom" 2>/dev/null; then
    tools=$(echo "$tools" | jq '. + {"headroom": {"status": "installed", "capabilities": ["token-compression", "content-routing", "ccr"]}}' 2>/dev/null || echo "$tools")
  fi

  # NVIDIA SkillSpector (pip package)
  if python3 -c "import skillspector" 2>/dev/null || command -v skillspector &>/dev/null; then
    tools=$(echo "$tools" | jq '. + {"skillspector": {"status": "installed", "capabilities": ["security-scan", "risk-scoring"]}}' 2>/dev/null || echo "$tools")
  fi

  # skill-security (our own grep-based scanner — always available)
  tools=$(echo "$tools" | jq '. + {"skill-security": {"status": "builtin", "capabilities": ["pattern-scan", "baseline"]}}' 2>/dev/null || echo "$tools")

  # caveman-ponytail / format-validator (always active via skill system)
  tools=$(echo "$tools" | jq '. + {"caveman-ponytail": {"status": "active", "capabilities": ["output-compression", "code-minimalism"]}}' 2>/dev/null || echo "$tools")

  echo "$tools"
}

# ── Runtime JSON ──────────────────────────────────────────

generate_runtime() {
  local tools
  tools=$(detect_tools)
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  cat > "$RUNTIME_FILE" <<RUNTIMEEOF
{
  "agentos": "runtime",
  "version": "0.1.0",
  "generated_at": "$timestamp",
  "tools": $tools,
  "pipeline": {
    "input": ["headroom", "codebase-memory-mcp"],
    "context": ["brain", "caveman-ponytail"],
    "output": ["caveman-ponytail"],
    "gate": ["skill-security", "format-validator"],
    "log": ["agentsview"]
  },
  "routes": {
    "code": "codebase-memory-mcp",
    "research": "opencli",
    "security": "skill-security",
    "compression": "caveman-ponytail",
    "session": "agentsview"
  }
}
RUNTIMEEOF
  echo "✅ agentos.json 已產生: $RUNTIME_FILE"
}

# ── Init ──────────────────────────────────────────────────

cmd_init() {
  echo "🔍 偵測本機工具…"
  local tools
  tools=$(detect_tools)
  local count
  count=$(echo "$tools" | jq 'length')
  echo "   發現 $count 個工具"
  generate_runtime
  echo ""
  echo "可用工具:"
  echo "$tools" | jq -r 'to_entries[] | "  \(.key) — \(.value.capabilities | join(", "))"'
  echo ""
  echo "Pipeline:"
  echo "  Input → headroom / codebase-memory-mcp"
  echo "  Context → brain / caveman-ponytail"
  echo "  Output → caveman-ponytail"
  echo "  Gate → skill-security / format-validator"
  echo "  Log → agentsview"
}

# ── Tools ─────────────────────────────────────────────────

cmd_tools() {
  if [[ ! -f "$RUNTIME_FILE" ]]; then
    echo "⚠️ 尚未執行 init，先跑: ./agentos.sh init"
    exit 1
  fi
  cat "$RUNTIME_FILE" | jq '.tools'
}

# ── Health ────────────────────────────────────────────────

cmd_health() {
  echo "🧪 AgentOS Runtime Health"
  echo ""

  # AgentOS server
  if curl -sf "$BASE/health" &>/dev/null; then
    echo "  ✅ AgentOS server — $BASE"
  else
    echo "  ⚠️  AgentOS server — 未執行 (agentos.sh up)"
  fi

  # Tools
  if [[ -f "$RUNTIME_FILE" ]]; then
    jq -r '.tools | to_entries[] | "  \(if .value.status == "installed" or .value.status == "active" or .value.status == "builtin" then "✅" else "⚠️" end) \(.key) — \(.value.status)"' "$RUNTIME_FILE"
  else
    echo "  ⚠️  尚未執行 init"
  fi
}

# ── Run ───────────────────────────────────────────────────

cmd_run() {
  if [[ ! -f "$RUNTIME_FILE" ]]; then
    cmd_init
  fi
  # pass through to AgentOS run endpoint
  exec curl -sf -X POST "$BASE/task/run" \
    -H 'Content-Type: application/json' \
    -d "$(jq -n --arg t "$*" '{task: $t}')"
}

# ── Brain ─────────────────────────────────────────────────

cmd_brain() {
  local action="${1:-}"; shift || true
  case "$action" in
    read)    curl -sf "$BASE/knowledge/${1:-}";;
    write)   curl -sf -X POST "$BASE/knowledge?key=${1:-}" -H 'Content-Type: application/json' -d "{\"content\": \"${2:-}\"}";;
    search)  curl -sf "$BASE/knowledge?q=${1:-}";;
    *)       echo "用法: brain read|write|search"; exit 1;;
  esac
}

# ── Main dispatch ─────────────────────────────────────────

CMD="${1:-}"; shift || true
case "$CMD" in
  init)      cmd_init "$@";;
  tools)     cmd_tools "$@";;
  health)    cmd_health "$@";;
  run)       cmd_run "$@";;
  brain)     cmd_brain "$@";;
  up|down)   "${SCRIPT_DIR}/agentos-daemon.sh" "$CMD" 2>/dev/null || echo "請執行: ${SCRIPT_DIR}/agentos-daemon.sh $CMD";;
  --help|-h) usage;;
  "")        usage;;
  *)         echo "未知指令: $CMD"; usage; exit 1;;
esac