---
name: agentos
description: AgentOS Runtime — tool orchestration, brain, security gate. 自動偵測本機工具並路由任務。session 開始時先跑 `agentos.sh health`。
---

# AgentOS Runtime：工具橋接層

AgentOS 不再只是驗證層。它是 **runtime** — 讓不同工具（codebase-memory-mcp / OpenCLI / caveman-ponytail / SkillSpector / agentsview）在同一個 pipeline 裡協作。

## 架構

```
使用者任務
    │
    ▼
[Input Layer]   headroom (token壓縮) / codebase-memory-mcp (程式碼查詢)
    │
    ▼
[Context Layer] brain (跨 session 記憶) / blackboard (當前狀態)
    │
    ▼
[Execute]       依任務類型路由到對應 executor
    │
    ▼
[Output Layer]  caveman-ponytail (輸出壓縮 + [K]階梯 + R1-R4)
    │
    ▼
[Gate]          format-validator (前綴檢查) / skill-security (安全掃描)
    │
    ▼
[Log]           agentsview (session 分析)
```

## ⚡ 進場檢查（Immediate Action）

1. 執行 `agentos.sh health` 確認 runtime 狀態
2. 如果沒產生過 runtime.json → `agentos.sh init`
3. 如果有 `handoff-next-session.md` → 先讀它再接續
4. 讀 `~/agent-sandbox/agentos.json` 確認可用工具清單

## 📖 前置記憶召回

```python
MemoryLookup(query="agentos runtime tool orchestration pipeline", limit=3)
MemoryLookup(query="agentos API endpoint error", limit=2)
```

## ⚠️ Anti-hallucination

| ❌ 你可能會寫 | ✅ 正確呼叫 |
|-------------|-----------|
| `curl localhost:8000/task/run` | `~/agent-sandbox/scripts/agentos.sh run "..."` |
| 手動選工具 | 讓 runtime.json 的 routes 決定路由 |
| 跳過 `agentos.sh health` 直接跑 | 每次 session 開始先 health check |

## 🧠 Common Rationalizations

| 你心裡會想 | 事實 |
|-----------|------|
| 「這個任務不需要經過 AgentOS」 | 所有工作都經過 runtime。不經過 = 不使用腦庫/閘道。 |
| 「先跑再說，health check 浪費時間」 | health check 會發現 codebase-memory-mcp 沒在跑、agentsview 沒開。 |
| 「我知道要用哪個工具，不用看 routes」 | routes 是動態的——今天裝了新工具明天 routes 就變。檢查它。 |

## Runtime 指令

```bash
# 初始化（偵測工具 + 產生 agentos.json）
~/agent-sandbox/scripts/agentos.sh init

# 檢查所有工具狀態
~/agent-sandbox/scripts/agentos.sh health

# 列出可用工具
~/agent-sandbox/scripts/agentos.sh tools

# 執行任務（自動路由工具）
~/agent-sandbox/scripts/agentos.sh run "你的任務"

# 腦庫讀寫
~/agent-sandbox/scripts/agentos.sh brain read <key>
~/agent-sandbox/scripts/agentos.sh brain write <key> <value>
~/agent-sandbox/scripts/agentos.sh brain search <query>
```

## Pipeline 路由

`agentos.json` 定義了任務類型到工具的對應：

```
code-pregame → query codebase-memory-mcp (get_architecture / search_graph / trace_path)
research     → opencli (browser search / site API)
security     → skill-security (pattern scan / risk score)
compression  → caveman-ponytail (content-aware / ccr)
session-log  → agentsview (自動記錄，無需手動)
```

工作時不用記這些——檢查 `agentos.json` 的 routes 區塊。

## 工作流

1. Session 開始 → `agentos.sh health`
2. 任務進來 → 判斷任務類型 → 對應 tool 在 routes 中的定義
3. 執行程式碼前 → codebase-memory-mcp 查架構（可選但不虧）
4. 交付前 → format-validator + skill-security gate
5. 完成後 → MemoryWrite + brain 雙寫

## ✅ 完成回饋

```python
MemoryWrite(
    userNeed="<任務摘要>",
    approach="AgentOS Runtime pipeline",
    outcome="完成 / 部分完成 / 失敗",
    whatFailed="<工具路由或閘道的問題>",
    whatWorked="<有效的工具鏈>",
    tags=["agentos", "<task-type>", "<tool-used>"]
)
```

AgentOS brain 雙寫：
```bash
curl -sf -X POST "http://localhost:8000/knowledge?key=skill/agentos/last-run" \
  -H 'Content-Type: application/json' \
  -d "{\"content\": \"<摘要>\", \"metadata\": {\"outcome\": \"完成\"}}"
```

## 🔄 Skill Interface

### 輸出（寫入腦庫的 key）
- `skill/agentos/runtime-status` → runtime 連線狀態 + 工具清單
- `skill/agentos/last-run` → 最後一次執行的結果摘要
- `skill/agentos/pipeline` → 目前 pipeline 設定（包括 gate 啟用狀態）

### 輸入（從腦庫讀取的 key）
- `project/current/status` → 當前專案狀態
- `skill/template-batch/last-run` → batch 結果（template-batch 寫入）
- `shared/status-from-*` → 其他 Scream window 的狀態
