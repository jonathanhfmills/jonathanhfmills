# git-orchestrator

## Purpose
A personal orchestrator repository that manages project submodules, tracks daily work against an issue tracker, and records architectural decisions at the orchestrator level. It does not contain production code directly — instead it mounts client and personal projects as git submodules under `src/<repo-name>`, keeping planning and automation infrastructure in one place while each project retains its own git history, branch strategy, and deployment pipeline.

## Key Files
| File | Description |
|------|-------------|
| `GLOSSARY.md` | Canonical term definitions for orchestrator concepts (Project, Work Item, Daily Log, HITL tags, etc.) |
| `LANGUAGE.md` | Rejected framings, behavioral rules, and resolved ambiguities for AI agents |
| `CONTEXT.md` | Relationships, examples, Tags reference, and HITL classification framework |
| `CONTEXT-MAP.md` | High-level map of bounded contexts and their relationships |

## Subdirectories
| Directory | Purpose |
|-----------|---------|
| `docs/` | Planning records: ADRs (orchestrator-level) and daily work logs (see `docs/AGENTS.md`) |
| `src/` | Git submodules — one per mounted project (see `src/AGENTS.md`) |

## For AI Agents

### Working In This Directory
- This is the **orchestrator** repo. Never add project source code here directly; all code lives inside submodules under `src/`.
- All commits follow `tag: Description` format (Conventional Commits style, no scope, no footer). Valid tags: `feat`, `fix`, `bug`, `chore`, `docs`, `style`, `refactor`, `perf`, `test`, `infra`.
- The orchestrator operates on a single `main` branch with no feature branches. Submodules provide the isolation that would otherwise require branching.
- When updating a submodule pointer, commit the `.gitmodules` change and submodule pointer update atomically with a meaningful message.

### Common Patterns
- New daily work goes in `docs/tasks/YYYY-MM-DD.md` seeded from `docs/tasks/YYYY-MM-DD.md` (template).
- Planned-but-not-started work lives in the external issue tracker / GitHub Issues, not a local backlog file (see [ADR 0008](docs/adr/0008-retire-tasks-md.md)).
- ADRs belong in `docs/adr/` and cover orchestrator-level decisions only. Project-level decisions live inside the submodule's own `docs/adr/`.

## Dependencies

### Internal
- `src/[your-project]/` — project submodule; orchestrator tracks its HEAD pointer

### External
- Issue tracker (e.g. JIRA at `[your-instance].atlassian.net`) — source of truth for all work items; work item IDs (e.g. `PROJ-42`) appear in daily logs

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->

## Root-level Makefile

`Makefile` + `config/systemd/` at this root provision the gateway/GPU-inference accounts and services described in `docs/adr/0007-gateway-service-accounts.md` — `make help` for the full target list. This is orchestrator-root-scoped (spans the whole tree, touches system accounts), distinct from `src/workspace/Makefile`, which stays scoped to the Hermes Operator's own dev tooling.
