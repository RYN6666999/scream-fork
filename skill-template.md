---
name: your-skill-name
description: 一句話描述這個 skill 的用途和觸發條件。
---

# Skill Title

## ⚡ 進場檢查（Immediate Action）

> 填寫 AI agent 進入這個 skill 時「必須」做的第一件事。

1. 檢查 [關鍵檔案/目錄] 是否存在
2. 如果存在 → 走路徑 A
3. 如果不存在 → 走路徑 B / 轉交其他 skill
4. 檢查 [必要的環境條件]（Python 套件、服務是否在跑、API key）

## 📖 前置記憶召回（Pre-task Memory Recall）

> 強制：在執行任何操作前，先用 MemoryLookup 查詢相關歷史經驗。
> 如果召回結果中有 whatFailed → 不要重複踩坑。
> 如果召回結果中有 whatWorked → 優先採用。

```python
MemoryLookup(query="<相關關鍵詞>", limit=3)
```

## ⚠️ Anti-hallucination：常見錯誤

| ❌ 你可能會寫/做 | ✅ 正確作法 |
|----------------|-----------|
| 常見的錯誤 API 呼叫 | 正確的 API 呼叫 |
| 容易搞混的參數名稱 | 正確的參數名稱 |
| 常見的實作陷阱 | 正確的做法 |

> 原則是：這個 skill 的使用者（AI agent）**最容易搞錯什麼**，就列什麼。

## 🧠 Common Rationalizations：你的大腦會騙你

> 這是從 Superpowers (239k★) + Addy Osmani agent-skills (67k★) 驗證過的模式：
> agent 在執行任務時會不自覺繞路，這張表專門預測並封堵這些捷徑。

| 你心裡會想 | 事實 |
|-----------|------|
| 「這個任務很簡單，不需要照流程走」 | 問題就是任務。照流程走。 |
| 「先讓我多讀一些 context 再開始」 | 先檢查 skill 再讀 context，skill 會告訴你讀哪裡。 |
| 「這個不需要呼叫 skill，我直接做」 | 如果 skill 存在，就使用它。 |
| 「先快速做一個版本，等等再修」 | Bugs compound。一步做對比事後修復快 3x。 |
| 「我已經懂了，不用讀完整文件」 | 了解概念 ≠ 讀了文件。去讀。 |

> 如果你覺得有 **1% 的機率**某個 skill 可能適用 → **必須呼叫**。這不是可選的。

## 核心功能

### [功能一]

說明功能、語法、範例：

```bash
# 命令或程式碼範例
```

### [功能二]

...

## 工作流

1. 步驟一
2. 步驟二
3. 步驟三
4. 驗證

## 禁止事項

- ❌ [絕對不要做的事]
- ❌ [絕對不要做的事]

## ✅ 完成回饋（Post-task Memory Store）

> 強制：任務完成後必須執行 MemoryWrite，讓跨 session 能查到這次經驗。
> 如果 AgentOS brain 在線，同時寫入腦庫。

```python
MemoryWrite(
    userNeed="<一句話總結>",
    approach="<方法摘要>",
    outcome="完成 / 部分完成 / 失敗",
    whatFailed="<踩了什麼坑>",
    whatWorked="<什麼有效>",
    tags=["<skill-name>", "<task-type>"]
)
```

```bash
# Brain 雙寫（如果 $AGENTOS_URL 可達）
curl -sf -X POST "$AGENTOS_URL/knowledge?key=skill/<你的-skill-name>/last-run" \
  -H 'Content-Type: application/json' \
  -d '{"content": "<任務摘要>", "metadata": {"outcome": "完成"}}'
```

## 🔄 Skill Interface

### 輸出（寫入腦庫 / 跨 session 記憶的 key）
- `skill/<你的-skill-name>/<key>` → 說明這個輸出的用途

### 輸入（從腦庫讀取的 key）
- `skill/<其他-skill-name>/<key>` → 依賴的其他 skill 輸出
- `project/current/status` → 當前專案狀態（通用 key）
