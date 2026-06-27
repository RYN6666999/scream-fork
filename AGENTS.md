# Scream Code

AI 輔助編程 CLI — v0.5.13

## 這是什麼

Scream Code 是一個以 agent 為中心的開發 CLI。你現在就在用我（Scream），而這個檔案是寫給我看的——讓我知道專案的架構、慣例、開發指令。

---

## Tech Stack

- **Runtime**：Node.js（`#!/usr/bin/env node`）
- **語言**：TypeScript，compile 到單一 JS script
- **資料庫**：SQLite-based 記憶引擎（`memory/` 目錄）
- **技能系統**：`SKILL.md` 格式，支援 scope 合併（Project > User > Extra > Built-in）
- **提供者**：OpenRouter（deepseek-v4-flash），1M context
- **工具**：Read / Write / Edit / Bash / Glob / Grep / WebSearch / FetchURL / Agent / MemoryLookup / MemoryWrite / CronCreate / TaskList / 等

---

## 架構總覽

```
~/.scream-code/               # Scream Code 設定與資料目錄
├── config.toml               # 模型提供者設定
├── tui.toml                  # 終端機 UI 偏好
├── device_id                 # 裝置識別
├── memory/                   # 跨 session 記憶
│   ├── entries.db            # 記憶條目
│   └── index/                # 檢索索引
├── skills/                   # 專案級技能（Project scope）
│   ├── agentos/SKILL.md
│   ├── template-batch/SKILL.md
│   └── troubleshooter/SKILL.md
├── .claude-plugin/           # Plugin marketplace 格式
│   ├── plugin.json
│   └── marketplace.json
├── sessions/                 # 持久化 session 資料
├── logs/                     # 執行日誌
└── updates/                  # 更新資訊

~/.agents/                    # 使用者級技能（User scope）
├── skills/                   # 40+ 通用技能
├── references/               # 技能參考文件
└── .skill-lock.json          # 技能版本鎖定
```

---

## 開發指令

```bash
# 啟動新 session
scream

# 恢復已暫停的 session
scream resume <session-id>

# 列出 session
scream ls
```

---

## Rules

⛔ **Rule #0 — 禁止問「接下來做什麼」。這是最高優先級，高於其他所有規則。**

Task 完成後，**不允許**問下列任何一句話：
- 「要繼續嗎」「下一步做什麼」
- 「你選哪個」「要從哪個開始」
- 「怎麼做」「要開始嗎」
- 「你決定」「你有想往那個方向嗎」
- 任何形式的「要不要」「好不好」「可以嗎」

**正確行為**：Task 完成後自動分析上下文，找出最有價值的下一步，直接開始執行。不需要請示。

如果不確定下一步 → 選擇一個合理的方向先做，如果走偏了使用者會拉你回來。

1. **技能先行** — 任務匹配到可用 skill 時，必須呼叫 Skill tool，不要自己繞路
2. **記憶查詢** — 遇到不熟悉的問題、或使用者提到之前做過的事，先用 MemoryLookup
3. **最小變更** — 只改需要的部分，不要重構沒人要求的東西
4. **驗證後交付** — 修改程式碼後一定要 verify（build / test / lint）
5. **狀態感知** — 每個 skill 開頭都有進場檢查，讀它、照它做
6. **不要假設 API** — 特別是 Base44 / AgentOS 的 API 名稱，查 skill 的 anti-hallucination 表
7. **跨 session 通透** — 使用 MemoryWrite 保存重要決策，讓未來的我能接續
8. **雙語輸出** — 使用者用什麼語言問，就用什麼語言答
9. **🔴 每 task 結束必須 MemoryWrite** — 不管成功或失敗，都必須執行完成回饋（見 skill 中的 `## ✅ 完成回饋` 區塊）。這不是選項，是強制協議。
10. **🔴 每 task 開始必須 MemoryLookup** — 在執行任何操作前，先用 MemoryLookup 查相關歷史經驗。避免重複踩坑。
11. **🔴 Session 結束協議** — 當 session 即將結束時：
    ```python
    # 1. 如果當前 task 已完成 → 寫入 MemoryWrite
    # 2. 如果 task 未完成 → 寫入 handoff-next-session.md
    # 3. 如果腦庫在線 → curl POST /knowledge 寫 session_end 摘要
    MemoryWrite(
        userNeed="session 摘要：<本次 session 做了什麼>",
        approach="<採用的方法>",
        outcome="完成 / 部分完成 / 中斷",
        whatFailed="<未解決的問題>",
        whatWorked="<本次 session 的關鍵進展>",
        tags=["session-summary"]
    )
    ```

---

## 🔄 Session 初始化（必須執行）

每次新 session 開始時，按順序做以下三步：

### Step 1: 召回歷史決策
```python
MemoryLookup(query="autonomy Rule #0 no questions", limit=3)
MemoryLookup(query="validate-response.sh format validator", limit=2)
```

### Step 2: 重建 cron safety net
```python
CronList()
# 如果沒有包含「自主性檢查」的 cron → 重建：
# CronCreate(cron="*/2 * * * *", prompt="自主性檢查 cron...", recurring=True)
```

### Step 3: 確認 Rule #0 生效
直接確認：不問使用者「要不要繼續」，完成 task 後自動判斷下一步。

---

## 可用的技能

| Skill | 用途 | Scope |
|-------|------|-------|
| `agentos` | AgentOS 基礎設施層：驗證、調度、跨 session 記憶 | Project |
| `template-batch` | 精準模板批次工作流：名牌、海報、識別證 | Project |
| `troubleshooter` | 標準化排查流程：build/test/連線/agent 異常 | Project |
| `agentos-bridge` | 跨 Scream window 腦庫橋接 | User |

一般技能（User scope）在 `~/.agents/skills/` 下，共 40+ 個。

---

## 更新 AGENTS.md 的時機

- 新增 / 移除技能時
- 技術棧變更時
- 開發流程變更時