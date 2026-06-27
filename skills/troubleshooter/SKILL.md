---
name: troubleshooter
description: 標準化排查流程。當遇到 build fail、test fail、連線異常、agent 行為異常時呼叫。提供分層式排查步驟與升級路徑。
---

# Troubleshooter — 標準化排查流程

遇到問題時不要 ad-hoc 亂試。先走標準流程。

---

## ⚡ 進場檢查

1. 先確認問題類型（build fail / test fail / 連線異常 / agent 異常）
2. 走到對應章節
3. 每一步做完都確認問題是否已解決
4. 如果 3 步內沒解決 → 升級

---

## 📖 前置記憶召回（Pre-task Memory Recall）

```python
MemoryLookup(query="troubleshoot build fail error agentos", limit=3)
MemoryLookup(query="known issues recurring problem", limit=2)
```

## 📂 Build Fail

```bash
# 1. 看完整錯誤訊息（不要只看最後一行）
<command> 2>&1 | tail -50

# 2. 檢查最近變更
git log --oneline -10

# 3. 檢查 node/bun/python 版本是否符合專案要求
node --version
bun --version
python3 --version

# 4. 清 cache 重試
# JavaScript/TypeScript
rm -rf node_modules .next dist && npm/bun install
# Python
uv sync --reinstall
```

**升級路徑**：如果上述都試過還是紅 → 貼完整錯誤給使用者，問是否要開 issue。

---

## 🧪 Test Fail

```bash
# 1. 只看失敗的 test（不要淹沒在 output 裡）
npm/pnpm/bun run test 2>&1 | grep -E "(FAIL|fail|✗|✘|×|Error)"

# 2. 讀失敗 test 的程式碼，理解它預期什麼
# 3. 實行修復 → 只跑相關 test 驗證
# 4. 全跑確保沒 regression
```

**注意**：
- ❌ 不要隨便改 test 來讓它 pass
- ❌ 不要跳過 test 來交付
- ✅ 理解預期行為後修正 source code

**升級路徑**：如果 test 預期行為不合理（spec 改了但 test 沒更新）→ 問使用者確認。

---

## 🔌 連線異常（AgentOS / API / Database）

```bash
# 1. 檢查服務是否在跑
curl -sf localhost:8000/health          # AgentOS
curl -sf localhost:5432                 # Postgres（可能拒絕但要有回應）
ping -c 1 api.example.com

# 2. 檢查 port 占用
lsof -i :8000

# 3. 重啟服務
~/agent-sandbox/scripts/agentos.sh up

# 4. 檢查 .env / credentials 是否存在
test -f .env && echo "exists" || echo "missing"
```

**升級路徑**：服務起不來 → 檢查 log：`tail -50 ~/agent-sandbox/logs/server.log` → 仍然無解 → 問使用者。

---

## 🤖 Agent 行為異常

| 症狀 | 第一步 | 第二步 |
|------|--------|--------|
| 答非所問 | 檢查 context window 是否滿了 | 開新 session |
| 工具呼叫失敗 | Read tool error message | 確認檔案路徑 / API 格式 |
| 一直重複同一動作 | 可能是 rate limit 或 tool 回傳異常 | 暫停 → 問使用者 |
| 記憶混亂 | 執行 MemoryLookup 確認歷史 | 必要時執行 /dream 整理 |

**升級路徑**：仍異常 → 檢查 `handoff-next-session.md` 看是否有已知問題。

---

## 🔄 通用檢查清單

當你不確定問題在哪時，按順序做：

```bash
# 1. 環境
echo "PWD: $(pwd)"
echo "PATH: $(which scream)"
echo "Bun: $(bun --version 2>/dev/null || echo N/A)"
echo "Node: $(node --version 2>/dev/null || echo N/A)"
echo "Python: $(python3 --version 2>/dev/null || echo N/A)"

# 2. 檔案完整性（專案依賴）
test -f package.json && echo "package.json ✅" || echo "package.json ❌"
test -f bun.lock && echo "bun.lock ✅" || echo "bun.lock ❌"
test -d node_modules && echo "node_modules ✅" || echo "node_modules ❌"
test -d .git && echo "git repo ✅" || echo "git repo ❌"

# 3. 最近 git 狀態
git status --short
```

---

## ✅ 完成回饋（Post-task Memory Store）

問題解決後保存經驗：

```python
MemoryWrite(
    userNeed="<問題類型> 排查與修復",
    approach="troubleshooter 標準流程",
    outcome="已解決 / 未解決 / 升級",
    whatFailed="<無效的排查方向>",
    whatWorked="<有效找到根因的方法>",
    tags=["troubleshooter", "<問題類別>"]
)
```

如果發現新的 known issue，更新腦庫：
```bash
curl -sf -X POST "http://localhost:8000/knowledge?key=skill/troubleshooter/known-issues" \
  -H 'Content-Type: application/json' \
  -d "{\"content\": \"<新發現的問題>\", \"metadata\": {\"status\": \"open\"}}"
```

## 🔄 Skill Interface

### 輸出（寫入腦庫的 key）
- `skill/troubleshooter/last-run` → 最近一次排查的結果摘要
- `skill/troubleshooter/known-issues` → 已知未解問題列表

### 輸入（從腦庫讀取的 key）
- `skill/agentos/status` → AgentOS 是否正常運作
- `project/current/status` → 當前專案狀態（可能包含已知問題）