<!-- Parent: AGENTS.md -->

# docs

## Purpose
Central planning directory for the orchestrator. Contains two concerns: architectural decision records (ADRs) that document hard-to-reverse decisions made at the orchestrator level, and daily work logs that record in-progress and completed work items per day. Neither project source code nor project-level ADRs belong here — those live inside the respective submodule.

## Subdirectories
| Directory | Purpose |
|-----------|---------|
| `adr/` | Architectural Decision Records for the orchestrator (see `adr/AGENTS.md`) |
| `tasks/` | Daily work logs, one file per day, plus a template (see `tasks/AGENTS.md`) |

## For AI Agents

### Working In This Directory
- Do not create files directly in `docs/` — content goes into `adr/` or `tasks/` subdirectories.
- ADRs cover **orchestrator-level** decisions only (git workflow, commit conventions, task tracking location). Project decisions belong in `src/<repo>/docs/adr/`.
- Daily logs follow the filename pattern `YYYY-MM-DD.md`. Copy `tasks/YYYY-MM-DD.md` as the template for new days.

### Common Patterns
- ADR filenames: zero-padded four-digit sequence number followed by a short kebab-case title (e.g. `0001-git-workflow.md`).
- Daily log line items carry a tag prefix (`feat`, `fix`, `chore`, etc.) matching the Conventional Commits type that will appear in the resulting commit message.
- Completed line items are marked `[x]`; in-progress or planned items remain `[ ]`.

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
