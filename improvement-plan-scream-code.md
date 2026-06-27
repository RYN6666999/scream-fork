# Scream Code 提升計劃 — 從 Base44 學到的七件事

> 基於對 Base44 組織 (github.com/base44) 九個 Repos 的深入研究，
> 對標 Scream Code v0.5.13 現狀，提出可行性提升方案。

---

## 目錄

1. [現狀盤點](#1-現狀盤點)
2. [七項提升](#2-七項提升)
3. [實施路徑](#3-實施路徑)
4. [不做什麼](#4-不做什麼)

---

## 1. 現狀盤點

### Scream Code 已有（別重造）

| 資產 | 現狀 |
|------|------|
| **技能系統** | `~/.scream-code/skills/`（3 個專案技能）+ `~/.agents/skills/`（40+ 通用技能），`SKILL.md` 格式 |
| **AGENTS.md** | 專案根目錄可放置，Scream 會自動讀取合併 |
| **記憶系統** | `memory/` 目錄 + `MemoryWrite`/`MemoryLookup` 工具，跨 session |
| **背景任務** | `Bash(run_in_background=true)` + `TaskList`/`TaskOutput`/`TaskStop` |
| **Cron 排程** | `CronCreate`/`CronDelete`/`CronList`，支援 recurring + one-shot |
| **版本鎖定** | `~/.agents/.skill-lock.json` 追蹤技能來源與版本 |
| **Session 持久** | `sessions/` 目錄，可 `scream resume` |
| **更新機制** | `updates/latest.json`，有更新通道 |

### Scream Code 缺少的（從 Base44 學來的）

| 缺口 | Base44 怎麼做的 |
|------|----------------|
| **SKILL.md 無狀態感知** | 開頭先檢查 `config.jsonc` 存在否，自動分流到 CLI/SDK/Troubleshooter |
| **SKILL.md 無 Anti-hallucination** | 每個模組有「❌ 錯的 vs ✅ 對的」表格 |
| **無 Plugin Marketplace 格式** | `.claude-plugin/plugin.json` + `marketplace.json`，跨平台安裝 |
| **技能與程式碼脫鉤** | AI Code Action 在發版時自動更新 SKILL.md + 開 PR |
| **無 AI-native 開發者入口** | CLI repo 有 `AGENTS.md` + `CLAUDE.md`，寫給 AI 讀的架構總覽 |
| **無 Troubleshooter 技能** | 專門除錯 skill，標準化 log 查詢流程 |
| **無 PR Agent Review** | `claude-code-review.yml` Action 自動審查 PR |
| **技能無對外散佈管道** | Plugin marketplace 讓任何 agent 平台都能安裝 |

---

## 2. 七項提升

### P1：SKILL.md 品質升級 — 狀態感知 + Anti-hallucination

**做法**：在每個 SKILL.md 加上三區塊：
- `⚡ 進場檢查（Immediate Action）` — 檢查必備條件，存在/不存在分流
- `⚠️ Anti-hallucination` — ❌ 錯的 vs ✅ 對的表格
- `🔄 Skill Interface` — 跨 skill 協定

### P2：Plugin Marketplace 打包

**做法**：建立 `.claude-plugin/` 目錄結構，這是 Claude Code / Codex / Cursor 等 agent 平台的安裝格式。

### P3：Auto-sync Pipeline

**做法**：GitHub Action 在發版時自動將 source code 中的 docstring/OAS 萃取成 SKILL.md，開 PR 到 `.scream-code/skill-sources/`。

### P4：CLI AGENTS.md 補完

**做法**：在開發專案根目錄放 `AGENTS.md`，寫給 AI 讀的技術規格、架構、開發指令、troubleshooting。

### P5：Troubleshooter Skill

**做法**：標準化排查流程，覆蓋 build fail / test fail / 連線異常 / agent 異常。

### P6：跨 Window 協定

**做法**：定義 Skill Interface 區塊，每個 skill 宣告它輸出和需要的腦庫 key。

### P7：CI/CD Agent Review

**做法**：GitHub Workflow 用 Claude Code 自動審查每個 PR。

---

## 3. 實施路徑

```
Phase 1 — 立即見效（1-2 天）
├── P1：改寫 agentos SKILL.md（加 state check + anti-hallucination）
├── P1：改寫 template-batch SKILL.md（加 state check + anti-hallucination）
└── P5：建立 troubleshooter SKILL.md

Phase 2 — 基礎建設（3-5 天）
├── P2：建立 .claude-plugin/ 目錄結構 + plugin.json
├── P4：在你的開發專案補 AGENTS.md
└── P6：在現有 skill 補上 Skill Interface 區塊

Phase 3 — 自動化（視需要）
├── P3：在 agent-sandbox 加 auto-sync workflow
└── P7：加 PR review workflow

Phase 4 — 常態化
├── 新 skill 模板預設包含 state check / anti-hallucination / interface 三區塊
└── 定期（月）檢視現有 skill 是否有 outdated 內容
```

---

## 4. 不做什麼

以下 Base44 有但 Scream **不適合直接複製**的事：

| Base44 做法 | 為什麼不適合 Scream |
|------------|-------------------|
| **Python skills repo**（79★） | Scream 的技能已經在 `~/.agents/`，不需要另開 repo 來放 |
| **全平台 SDK**（Swift/Kotlin） | Scream 是 Node CLI，跨平台 SDK 不是你的核心 |
| **Zero-dep npm bundle** | Scream 已經是 Node script，不需要 bundle |
| **Homebrew tap** | Scream 已經是 brew installable，tap 已存在 |
| **用 AI 寫的 onboarding 給 AI 看** | Idea 好但執行成本高，等技能體系穩定再做 |

---

## 總結

這七項提升的核心思想只有一句話：

> **把「教 AI 用你的工具」當成產品來設計，而不是文件來撰寫。**

| 面向 | 目前狀態 | 目標狀態 |
|------|---------|---------|
| SKILL.md | 描述性文件 | 狀態感知 + anti-hallucination |
| 技能散佈 | 自己用 | 可安裝 / 可分享 |
| 技能與 code | 手動維護 | 發版自動同步 |
| 開發者入口 | 無 | AGENTS.md |
| 排查流程 | ad-hoc | 標準化 playbook |
| 技能互通 | 無協定 | 明確 interface |
| PR review | 人工 | AI-assisted |