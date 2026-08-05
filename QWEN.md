<!-- <qwen>2026年5月10日</qwen> -->

# git-orchestrator

## Purpose
此乃個人協調庫，管理專案子模組，追蹤日常工作於問題追蹤器，並記錄架構決策於協調層級。不直含生產碼，蓋以客戶端及個人專案，掛載於 `src/<repo-name>` 下為 git 子模組，使規劃與自動化基礎設施匯聚於一處，同時各專案保有其 git 歷史、分支策略、部署管線。

## Key Files
| File | Description |
|------|-------------|
| `GLOSSARY.md` | 協調器概念標準術語定義（專案、工作項、日誌、HITL標籤等） |
| `LANGUAGE.md` | AI代理拒絕的框架、行為準則、已解決的歧義 |
| `CONTEXT.md` | 關聯、範例、標籤參考、HITL分類框架 |
| `CONTEXT-MAP.md` | 邊界上下文及其關係之高層圖 |

## Subdirectories
| Directory | Purpose |
|-----------|---------|
| `docs/` | 規劃記錄：ADRs（協調層級）及日常工作日誌（參見 `docs/AGENTS.md`） |
| `src/` | Git子模組—每掛載專案一項（參見 `src/AGENTS.md`） |

## For AI Agents

### Working In This Directory
- 此乃 **協調器** 儲庫。切勿於此直接增添專案源碼；所有程式碼皆存於 `src/` 下之子模組內。
- 所有提交遵循 `tag: Description` 格式（Conventional Commits 風格，無範圍，無尾注）。有效標籤： `feat`, `fix`, `bug`, `chore`, `docs`, `style`, `refactor`, `perf`, `test`, `infra`。
- 協調器運作於單一 `main` 分支，無特性分支。子模組提供原需分支隔離之用。
- 更新子模組指標時，應原子化提交 `.gitmodules` 變更與子模組指標更新，附以有意義訊息。

### Common Patterns
- 新增日常工作置於 `docs/tasks/YYYY-MM-DD.md`，其內容源自 `docs/tasks/YYYY-MM-DD.md`（範本）。
- 規劃中尚未啟動之工作項，歸於外部問題追蹤系統（issue tracker），不設本機積壓清單（見 ADR 0008）。
- ADRs 歸於 `docs/adr/`，僅涵蓋協調層級決策。專案層級決策則居於子模組自身 `docs/adr/` 內。

## Dependencies

### Internal
- `src/[your-project]/` — 專案子模組；協調器追蹤其 HEAD 指標

### External
- 問題追蹤器（例：JIRA 於 `[your-instance].atlassian.net`）— 所有工作項之真理之源；工作項 ID（例：`PROJ-42`）現於日誌。

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->