# Scream Code — Ryan's Fork

Base: `scream-code` v0.5.13 by LIUTod
Fork: Ryan @RYN6666999
Tracked from: 2026-06-19

## What's different

| Area | Original | Ryan's Fork |
|------|----------|-------------|
| Skills | 0 built-in | 40+ user skills + 3 project-scoped (`agentos`, `template-batch`, `troubleshooter`) |
| Plugins | 0 | 4 marketplace (caveman, ponytail, cloudflare, claude-plugins-official) |
| Plugin marketplace format | 0 | `.claude-plugin/plugin.json` + `marketplace.json` for distribution |
| Commands | 0 | 1 (`abb.md`) |
| Projects | 0 | 20+ (nanoclaw, agent-sandbox, gbrain, LB-\*, etc.) |
| Rules | 0 | `common/` + `AGENTS.md` in `.scream-code/` + `CLAUDE.md` in agent-sandbox |
| Output style | full prose | caveman compression (fragments, no filler) |
| Code style | standard | ponytail ladder (YAGNI → stdlib → native → min) |
| Third-party integrations | 0 | nanoclaw Telegram bot, AgentOS, LifeBuilder ecosystem |
| CI/CD workflows | 0 | 3 in agent-sandbox (test, claude-code-review, sync-agentos-skill) |
| Memory system | none | SQLite-based cross-session memory with auto-consolidation + /dream |
| Cron scheduler | none | Built-in cron with recurring + one-shot, 7-day auto-stale |
| Skill sync pipeline | none | GitHub Action auto-updates SKILL.md on source code release |

## Key additions

### Skill: caveman-ponytail (user-created)
Merges two open-source philosophies:
- **Caveman** (JuliusBrussee) — output token compression ~65%
- **Ponytail** (DietrichGebert) — code minimalism 80-94%
- Plus Scream Code-specific extensions (parallel tool calls, WolfPack, anchor validation)

### Skill: track-scream-mods (user-created)
Long-running change tracker. Auto-checks weekly via cron.

### 🔥 New: Project-scoped Skills (`.scream-code/skills/`)

Following Base44's architecture, project-specific skills are now stored in `.scream-code/skills/`:

| Skill | Description |
|-------|-------------|
| **agentos** | AgentOS infrastructure layer — verification, brain, task queue |
| **template-batch** | Precision template batch workflow — badges, posters, IDs |
| **troubleshooter** | Standardized troubleshooting — build/test/connection/agent issues |

Each upgraded with:
- `⚡ 進場檢查（Immediate Action）` — state-aware auto-routing
- `⚠️ Anti-hallucination` table — wrong vs correct API calls
- `🔄 Skill Interface` — cross-skill brain communication protocol

### 🔥 New: Plugin Marketplace Format

```
.scream-code/
├── .claude-plugin/
│   ├── plugin.json          # Points to 3 skills
│   └── marketplace.json     # Marketplace registration
├── AGENTS.md                 # Architecture overview for AI agents
└── skill-template.md         # Template with 3 mandatory blocks
```

This enables installation by any Claude Code / Codex / Cursor agent via marketplace.

### 🔥 New: CI/CD Automation (agent-sandbox)

| Workflow | Description |
|----------|-------------|
| `claude-code-review.yml` | AI code review on every PR |
| `sync-agentos-skill.yml` | Auto-update SKILL.md on release |
| `CLAUDE.md` | Tech spec + architecture for AI developers |

### Plugins installed
- `caveman` — output compression
- `ponytail` — lazy senior dev mode
- `cloudflare` — Cloudflare integration
- `claude-plugins-official` — official plugin set

## Projects managed by this agent

- `nanoclaw` — Telegram AI assistant (gemini/grok multi-tier)
- `agent-sandbox` — AgentOS Maker/Checker framework
- `LB-arcanum/numen/nexus/nuntius` — LifeBuilder ecosystem
- `super-engine` — Web LLM driver
- `mcp-hub-mvp` — MCP hub server
- `life-builder31491` — Infinite Mandalart PM
- `fdd-crm/reception` — 房多多 CRM
- `meta-agent`, `HMM` — experimental

## Auto-tracking

This repo auto-updates via:
1. `track-scream-mods` skill (manual: invoke skill)
2. Cron job every Monday 09:00 (auto: `track.sh`)
3. Snapshots saved to `_snapshot-*.md`

See `CHANGELOG.md` for history.