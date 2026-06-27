# Changelog — Scream Code 自訂版本

追蹤 scream-code v0.5.13 原始版 → Ryan 自訂版的所有變更。

## 2026-06-19 — 初始追蹤建立

### 新增技能（7）
- caveman-ponytail
- claude-code-bash-patterns
- codebase-analysis
- debug
- git-workflow
- planning-with-files
- test-driven-development
- track-scream-mods

### 已安裝 plugin（4）
- caveman
- claude-plugins-official
- cloudflare
- ponytail

### 自訂指令
- abb.md

### 活躍專案（18）
- -Users-ryan
- -Users-ryan--claude-worktrees-nanoclaw-mystifying-goldstine
- -Users-ryan--claude-worktrees-nanoclaw-sleepy-nightingale
- -Users-ryan-agent-sandbox
- -Users-ryan-ComfyUI
- -Users-ryan-gbrain
- -Users-ryan-gbrain--claude-worktrees-compassionate-tu-125a92
- -Users-ryan-gbrain--claude-worktrees-exciting-lichterman-2785f0
- -Users-ryan-gbrain--claude-worktrees-hopeful-swanson-4ffd48
- -Users-ryan-gbrain--claude-worktrees-interesting-dijkstra-d61762
- -Users-ryan-gbrain--claude-worktrees-modest-jones-85d224
- -Users-ryan-gbrain--claude-worktrees-vigorous-ride-b584cc
- -Users-ryan-Library
- -Users-ryan-meta-agent
- -Users-ryan-nanoclaw
- -Users-ryan-nanoclaw-nanoclaw
- -Users-ryan-project-golem

## 2026-06-27 — Base44 啟發的全域升級（Phase 1-3）

### 新增專案級 Skill（3）
- `agentos`（升級：進場檢查 + anti-hallucination + interface）
- `template-batch`（升級：進場檢查 + anti-hallucination + interface）
- `troubleshooter`（新建：標準化排查流程）

### 新增基礎建設
- `.claude-plugin/plugin.json` + `marketplace.json` — Plugin marketplace 格式
- `AGENTS.md` — 寫給 AI 開發者看的架構總覽
- `skill-template.md` — 新 Skill 模板（進場檢查 / anti-hallucination / interface）
- `improvement-plan-scream-code.md` — 完整提升計畫

### 新增自動化 (agent-sandbox)
- `CLAUDE.md` — 技術規格 + 架構圖 + 開發指令
- `.github/workflows/claude-code-review.yml` — PR 自動 AI 審查
- `.github/workflows/sync-agentos-skill.yml` — 發版自動更新 SKILL.md
- `.scream-code/skill-sources/agentos/SKILL.md` — Skill source of truth

### 跨 Skill Interface 互通網路
```
agentos ── skill/agentos/status ──→ template-batch, troubleshooter, agentos-bridge
template-batch ── skill/template-batch/last-run ──→ agentos
agentos-bridge ── shared/status-from-* ──→ agentos
```
