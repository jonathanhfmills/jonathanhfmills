# Backlog

Forward-looking task list. Move items to `docs/tasks/YYYY-MM-DD.md` when work begins.

## jonathanhfmills/dotfiles-wsl → dotfiles-template

### [dotfiles-wsl#8] Seed dotfiles-template from dotfiles-wsl

- [ ] [HITLFE] feat: Strip personal content (agents/, debates/, bicameral-mind/, openclaw.json, nullclaw tests, hindsight .mcp.json)
- [ ] [HOOTL] feat: Push first commit to dotfiles-template on GitHub
- [ ] [HOOTL] infra: Register dotfiles-template as orchestrator submodule (unblocked after first commit)

### [dotfiles-wsl#9] Prune Makefile of personal/bicameral targets

- [ ] [HOOTL] chore: Remove debate/maintainer/observer/ralph/escalate/training-pr/digital-twin/agent-start/hindsight/llama-* targets
- [ ] [HOOTL] chore: Ensure omc target stays but is NOT wired into install:

### [dotfiles-wsl#10] Add SOC2-compliant settings.json to .claude stow package

- [ ] [HITLFE] feat: Write settings.json with OTEL (metrics+logs+traces beta), Anthropic telemetry disable, skipDangerousModePermissionPrompt: false
- [ ] [HIC] chore: Fill in OTEL_EXPORTER_OTLP_ENDPOINT and OTEL_EXPORTER_OTLP_HEADERS for org collector

### [dotfiles-wsl#11] Add shell/ stow package with claude-unsafe alias

- [ ] [HOOTL] feat: Create shell/aliases.sh with claude-unsafe → claude --dangerously-skip-permissions
- [ ] [HOOTL] chore: Add shell Makefile target + wire into link:

### [dotfiles-wsl#12] Update CLAUDE.md with SOC2 permission controls policy section

- [ ] [HOOTL] docs: Add section 8 (SOC2 permission controls) to .claude/CLAUDE.md template
- [ ] [HOOTL] docs: Remove OMC block from template CLAUDE.md (OMC manages its own block post-install)

### [dotfiles-wsl#13] Add SOC2-compliant Codex OTEL config to .codex stow package

- [ ] [HITLFE] feat: Write .codex/config.toml with [otel] otlp exporter, log_user_prompt=true, [analytics] disabled, [feedback] disabled
- [ ] [HIC] chore: Fill in OTLP endpoint + token for org collector

| Tag | Stands For | Meaning |
|-----|-----------|---------|
| `[HOOTL]` | Human-Out-of-the-Loop | AI executes autonomously; human audits after-the-fact if needed |
| `[HITLFE]` | Human-in-the-Loop for Exceptions | AI handles routine prep, escalates the exception to human for approval |
| `[HIC]` | Human-in-Command | Human-only task — AI excluded; human retains full responsibility |

> Full HITL orchestration spec — thresholds, behavioral rules, and design rationale — in [`CONTEXT.md`](./CONTEXT.md).
