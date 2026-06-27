---
name: agentos
description: 接上 AgentOS 基礎設施層。使用者說「啟動 agentos / 接上辦公室 / 連 AgentOS」、或任務涉及真實驗收(pytest)、跨 session 記憶(腦庫)、背景佇列/自修復時呼叫。
---

# AgentOS：你的基礎設施層（CLI 辦公室）

你（Scream）是執行主體：計劃、寫 code、判斷交付。**AgentOS 是你呼叫的工具，不是它指揮你。**
它不寫 code、不決策，只做四件事：safety gate / 真實驗收(真跑 pytest) / 審計 / 調度(腦庫+黑板+佇列)。

## ⚡ 進場檢查（Immediate Action）

1. 檢查 `~/agent-sandbox` 存在且 `api/main.py` 在
2. 如果 AgentOS server 沒在跑（`curl -sf localhost:8000/health` 失敗）
   → 執行 `~/agent-sandbox/scripts/agentos.sh up`
3. 如果 `handoff-next-session.md` 存在
   → 先讀它再接續

## 📖 前置記憶召回（Pre-task Memory Recall）

在執行任何操作之前，先查詢相關歷史經驗：

```python
# 語意：搜尋過去與 AgentOS 相關的經驗
MemoryLookup(query="agentos verify task brain knowledge", limit=3)
MemoryLookup(query="agentos API endpoint error", limit=2)
```

如果召回結果包含相關的 whatFailed/whatWorked → **優先參考**，不要重複踩坑。

## ⚠️ Anti-hallucination：常見錯誤

| ❌ 你可能會寫 | ✅ 正確呼叫 |
|-------------|-----------|
| `/task/run` | `/task/verify`（沒有 run 端點） |
| `agentos.sh verify` | `agentos.sh run "任務"`（全走 `run`） |
| `knowledge write` | 用 `POST /knowledge`（沒有 `knowledge-write` 腳本） |
| `curl localhost:8000/task/verify` | `~/agent-sandbox/scripts/agentos.sh run "..."`（用腳本不要直接 curl） |

## 🧠 Common Rationalizations

| 你心裡會想 | 事實 |
|-----------|------|
| 「只是跑個 verify，不用走 agentos 流程」 | 每次 verify 都要經過 AgentOS，這是強制關卡。 |
| 「這個改動很小，跳過 safety gate 沒關係」 | Safety gate 不是針對改動大小，是針對不可逆操作。 |
| 「先直接改 code 再補腦庫記錄」 | 先寫腦庫再動手，確保記憶不被遺漏。 |
| 「我上次用過一樣的指令，這次不用查」 | API 會變。查 anti-hallucination 表，不要憑記憶。 |

## 接上（多半已經是接著的）

server 已設成登入自動常駐（macOS LaunchAgent），所以多半已在 `:8000`。確認/手動起：

```bash
~/agent-sandbox/scripts/agentos.sh up      # 沒跑就自動起+接上；已跑直接用（idempotent）
```

## 怎麼用

```bash
~/agent-sandbox/scripts/agentos.sh run "任務"            # 同步執行
~/agent-sandbox/scripts/agentos.sh knowledge-read <k>    # 讀腦庫（跨 session 記憶）
~/agent-sandbox/scripts/agentos.sh knowledge-search "q"  # 全文搜尋（中文走 LIKE）
~/agent-sandbox/scripts/agentos.sh executors             # 列可用工具
```

HTTP（`localhost:8000`）：`/task/verify`（真跑 pytest 回 pass/retry/escalate，並自動萃取 gene 存腦庫）、
`/queue/push`（背景任務 → 自修復迴圈會自己改 repo 修紅測試）、`/knowledge/{key}`、`/blackboard/{key}`。
端點全表見 `~/agent-sandbox/README.md`。

## 工作流

- 要客觀驗收 → 丟 `/task/verify`，別自己判斷綠燈。
- 要記東西跨 session → 腦庫 `knowledge-*`。
- 背景/自修復 → `/queue/push` + heartbeat daemon。
- 接手前讀 `~/agent-sandbox/.scream-code/handoff-next-session.md` 拿進度。

## 紅線

- 勿改核心：`orchestrator/checker.py` / `decision_log.py` / `safety.py` / `clarify.py`。
- 不可逆動作（commit/push/刪檔）先問人。
- 輸出繁體中文。

## ✅ 完成回饋（Post-task Memory Store）

任務完成後，**必須**執行 MemoryWrite 保存經驗以供跨 session 使用：

```python
MemoryWrite(
    userNeed="<一句話總結使用者要什麼>",
    approach="<採用的方法摘要>",
    outcome="完成 / 部分完成 / 失敗",
    whatFailed="<踩了什麼坑，沒有就寫 none>",
    whatWorked="<什麼做法有效，沒有就寫 none>",
    tags=["agentos", "<task-type>", "<關鍵技術>"]
)
```

AgentOS 腦庫雙寫（如果 brain 在線）：
```bash
curl -sf -X POST "http://localhost:8000/knowledge?key=skill/agentos/last-run" \
  -H 'Content-Type: application/json' \
  -d "{\"content\": \"<任務摘要>\", \"metadata\": {\"outcome\": \"<完成/失敗>\"}}"
```

## 🔄 Skill Interface

### 輸出（寫入腦庫的 key）
- `skill/agentos/status` → AgentOS 連線狀態（online/offline）
- `skill/agentos/last-verify` → 最後一次驗證結果摘要
- `skill/agentos/last-verify/{task_id}` → 單次驗證完整結果

### 輸入（從腦庫讀取的 key）
- `project/current/status` → 當前專案狀態摘要（其他 skill 寫入）
- `skill/template-batch/last-run` → 批次處理的產出摘要（template-batch skill 寫入）
- `shared/status-from-*` → 其他 Scream window 的狀態（agentos-bridge 協定）
