.PHONY: help gateway-accounts gateway-acls openclaw-gateway hermes-gateway cosmo-cli-config lms-cli lms-server desktop-tts desktop-stt gateways

.DEFAULT_GOAL := gateways

SHELL := /bin/bash
USERSPACE_ROOT := $(CURDIR)
HERMES_ROOT := $(USERSPACE_ROOT)/src/workspace

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "userspace-root dotfiles: account/GPU/gateway provisioning that spans the"
	@echo "whole orchestrator tree. Workspace-level (Hermes Operator) dev tooling"
	@echo "lives in src/workspace/Makefile instead -- see docs/adr/0007."
	@echo ""
	@echo "Gateways (run on wanda-box: 13600K, 32GB DDR4, AMD 9070 XT)"
	@echo "  gateway-accounts  Create/rename wanda, cosmo, lms no-sudo system accounts"
	@echo "  gateway-acls      POSIX ACLs: wanda rwx userspace + r-x hermes; cosmo rwx hermes only"
	@echo "  openclaw-gateway  Install + enable wanda's openclaw-scoped gateway systemd unit"
	@echo "  hermes-gateway    Install + enable cosmo's hermes-scoped gateway systemd unit"
	@echo "  cosmo-cli-config  Seed cosmo's own ~/.claude, ~/.codex, ~/.gemini, ~/.qwen (isolated credentials, not jon's/wanda's)"
	@echo "  lms-cli           Install LM Studio headless CLI (lms) under the lms account"
	@echo "  lms-server        Install + enable lms's shared GPU inference server unit (LM Studio: chat/vision only)"
	@echo "  gateways          gateway-accounts + gateway-acls + openclaw-gateway + hermes-gateway + cosmo-cli-config + lms-server"
	@echo ""
	@echo "Media (run on desktop: i7-8700K, RTX 3080, separate machine from wanda-box)"
	@echo "  desktop-tts       faster-qwen3-tts, native CUDA"
	@echo "  desktop-stt       faster-whisper turbo via speaches, native CUDA"

# =============================================================================
# Gateways: wanda (openclaw), cosmo (hermes), lms (shared GPU inference).
# These three targets/accounts all belong on ONE machine -- wanda-box (13600K,
# 32GB DDR4, AMD 9070 XT). See docs/adr/0007-gateway-service-accounts.md.
# These targets need sudo and touch a live account (renaming the existing
# openclaw system user to wanda) -- run individually and verify each step
# before moving to the next, rather than `make gateways` blind on a live box.
# =============================================================================

# -- Create/rename the three no-sudo service accounts ---------------------------
gateway-accounts:
	@if id wanda &>/dev/null; then \
		echo "wanda already exists"; \
	elif id user &>/dev/null && [ "$$(getent passwd user | cut -d: -f6)" = "/home/openclaw" ]; then \
		echo "Renaming existing 'user' (openclaw) account to wanda -- this account has a live gateway service, stop it first if running:"; \
		echo "  systemctl --user -M user@ stop openclaw-gateway.service"; \
		sudo usermod -l wanda -d /home/wanda -m user; \
		sudo usermod -c wanda wanda; \
		echo "Renamed. Update any remaining references to the old 'user'/'openclaw' login (cron, other unit files) by hand."; \
	else \
		echo "No existing 'user' account found at /home/openclaw -- creating wanda fresh"; \
		sudo useradd -r -m -s /bin/bash -c wanda wanda; \
	fi
	@if id cosmo &>/dev/null; then echo "cosmo already exists"; \
	else sudo useradd -r -m -s /bin/bash -c cosmo cosmo; fi
	@if id lms &>/dev/null; then echo "lms already exists"; \
	else sudo useradd -r -m -s /bin/bash -c lms lms; fi
	sudo usermod -aG video,render lms
	sudo loginctl enable-linger wanda cosmo lms
	@echo "Accounts ready: wanda, cosmo (no extra groups), lms (video, render)"

# -- POSIX ACLs enforcing the one-way visibility boundary -----------------------
gateway-acls:
	sudo setfacl -m u:wanda:--x /home/jon
	sudo setfacl -R -m u:wanda:rwx -m d:u:wanda:rwx "$(USERSPACE_ROOT)"
	sudo setfacl -R -m u:wanda:r-x -m d:u:wanda:r-x "$(HERMES_ROOT)"
	sudo setfacl -m u:cosmo:--x /home/jon
	sudo setfacl -R -m u:cosmo:rwx -m d:u:cosmo:rwx "$(HERMES_ROOT)"
	@echo "ACLs applied: wanda rwx userspace / r-x hermes subtree; cosmo rwx hermes subtree only"
	@echo "Verify with: getfacl $(USERSPACE_ROOT) && getfacl $(HERMES_ROOT)"

# -- wanda's openclaw-scoped gateway ---------------------------------------------
openclaw-gateway:
	@command -v jq >/dev/null || { echo "jq not found -- install it first (it's in src/workspace/Makefile's apt target, or: sudo pacman -S jq / sudo apt-get install jq)"; exit 1; }
	sudo -u wanda mkdir -p /home/wanda/.config/systemd/user
	sudo cp "$(CURDIR)/config/systemd/openclaw-gateway.service" /home/wanda/.config/systemd/user/openclaw-gateway.service
	sudo chown wanda:wanda /home/wanda/.config/systemd/user/openclaw-gateway.service
	sudo -u wanda XDG_RUNTIME_DIR=/run/user/$$(id -u wanda) systemctl --user daemon-reload
	sudo -u wanda XDG_RUNTIME_DIR=/run/user/$$(id -u wanda) systemctl --user enable --now openclaw-gateway.service
	@if sudo -u wanda test -f /home/wanda/.openclaw/openclaw.json; then \
		sudo -u wanda sh -c "jq --arg ws '$(USERSPACE_ROOT)' '.agents.defaults.workspace = \$$ws' /home/wanda/.openclaw/openclaw.json > /home/wanda/.openclaw/.openclaw.json.tmp && mv /home/wanda/.openclaw/.openclaw.json.tmp /home/wanda/.openclaw/openclaw.json"; \
		echo "openclaw.json agents.defaults.workspace -> $(USERSPACE_ROOT)"; \
	else \
		sudo -u wanda sh -c "jq --arg ws '$(USERSPACE_ROOT)' '.agents.defaults.workspace = \$$ws' '$(CURDIR)/config/openclaw/openclaw.json.example' > /home/wanda/.openclaw/openclaw.json"; \
		echo "Seeded /home/wanda/.openclaw/openclaw.json from config/openclaw/openclaw.json.example (workspace -> $(USERSPACE_ROOT))."; \
		echo "Fill in the SET_ME apiKey fields (its own credentials, restore the rest from the 1Password backup if this is the reinstalled desktop box, or set new ones)."; \
	fi

# -- cosmo's hermes-scoped gateway ------------------------------------------------
hermes-gateway:
	@command -v jq >/dev/null || { echo "jq not found -- install it first (it's in src/workspace/Makefile's apt target, or: sudo pacman -S jq / sudo apt-get install jq)"; exit 1; }
	sudo -u cosmo mkdir -p /home/cosmo/.config/systemd/user /home/cosmo/.openclaw
	sudo cp "$(CURDIR)/config/systemd/hermes-gateway.service" /home/cosmo/.config/systemd/user/hermes-gateway.service
	sudo chown cosmo:cosmo /home/cosmo/.config/systemd/user/hermes-gateway.service
	sudo -u cosmo XDG_RUNTIME_DIR=/run/user/$$(id -u cosmo) systemctl --user daemon-reload
	sudo -u cosmo XDG_RUNTIME_DIR=/run/user/$$(id -u cosmo) systemctl --user enable --now hermes-gateway.service
	@if sudo -u cosmo test -f /home/cosmo/.openclaw/openclaw.json; then \
		sudo -u cosmo sh -c "jq --arg ws '$(HERMES_ROOT)' '.agents.defaults.workspace = \$$ws | .gateway.port = 9119' /home/cosmo/.openclaw/openclaw.json > /home/cosmo/.openclaw/.openclaw.json.tmp && mv /home/cosmo/.openclaw/.openclaw.json.tmp /home/cosmo/.openclaw/openclaw.json"; \
		echo "openclaw.json agents.defaults.workspace -> $(HERMES_ROOT), gateway.port -> 9119"; \
	else \
		sudo -u cosmo sh -c "jq --arg ws '$(HERMES_ROOT)' '.agents.defaults.workspace = \$$ws | .gateway.port = 9119' '$(CURDIR)/config/openclaw/openclaw.json.example' > /home/cosmo/.openclaw/openclaw.json"; \
		echo "Seeded /home/cosmo/.openclaw/openclaw.json from config/openclaw/openclaw.json.example (workspace -> $(HERMES_ROOT), port -> 9119)."; \
		echo "Fill in the SET_ME apiKey fields with cosmo's OWN credentials -- do not reuse wanda's or jon's."; \
	fi

# -- cosmo's own claude/codex/gemini/qwen config, isolated from jon and wanda ----
# wanda gets the same treatment eventually (per docs/adr/0007) but is not MVP yet.
cosmo-cli-config:
	sudo -u cosmo mkdir -p /home/cosmo/.claude /home/cosmo/.codex /home/cosmo/.gemini /home/cosmo/.qwen
	sudo cp "$(CURDIR)/config/claude/settings.local.json" "$(CURDIR)/config/claude/.mcp.json" /home/cosmo/.claude/
	sudo chown -R cosmo:cosmo /home/cosmo/.claude /home/cosmo/.codex /home/cosmo/.gemini /home/cosmo/.qwen
	@echo "Seeded /home/cosmo/.claude with non-secret defaults (empty MCP servers, sandbox off)."
	@echo "codex/gemini/qwen dirs created empty -- each CLI populates its own defaults on first run."
	@echo "Each tool still needs its OWN login/API key for cosmo, separate from jon's and wanda's:"
	@echo "  sudo -u cosmo -i"
	@echo "  claude login   # (and the codex/gemini/qwen equivalents)"

# -- lms: shared GPU inference server (only account touching the GPU) -----------
lms-cli:
	@if sudo -u lms test -x /home/lms/.lmstudio/bin/lms; then \
		echo "lms CLI already installed"; \
	else \
		echo "lms CLI not found under /home/lms/.lmstudio/bin/lms."; \
		echo "No verified unattended install command for the headless CLI -- follow https://lmstudio.ai/docs/cli"; \
		echo "as the lms account (sudo -u lms -i), then re-run 'make lms-cli' to confirm."; \
	fi

lms-server: lms-cli
	sudo -u lms mkdir -p /home/lms/.config/systemd/user
	sudo cp "$(CURDIR)/config/systemd/lms-server.service" /home/lms/.config/systemd/user/lms-server.service
	sudo chown lms:lms /home/lms/.config/systemd/user/lms-server.service
	sudo -u lms XDG_RUNTIME_DIR=/run/user/$$(id -u lms) systemctl --user daemon-reload
	sudo -u lms XDG_RUNTIME_DIR=/run/user/$$(id -u lms) systemctl --user enable --now lms-server.service
	@echo "lms-server installed. wanda/cosmo call it over loopback at 127.0.0.1:1234 -- no GPU device access needed on their end."

gateways: gateway-accounts gateway-acls openclaw-gateway hermes-gateway cosmo-cli-config lms-server

# =============================================================================
# desktop: separate machine (i7-8700K, RTX 3080, native CUDA) -- NOT wanda-box.
# Runs TTS/STT as jon directly (no account sandboxing here; desktop isn't part
# of the wanda/cosmo/lms security boundary, just a GPU helper reachable over
# tailnet). See docs/adr/0007-gateway-service-accounts.md.
# =============================================================================

# -- faster-qwen3-tts, native CUDA (upstream-supported, no ROCm substitution needed) --
desktop-tts:
	git -C "$(HOME)" clone --depth 1 https://github.com/andimarafioti/faster-qwen3-tts.git 2>/dev/null || \
		git -C "$(HOME)/faster-qwen3-tts" pull --ff-only
	python3 -m venv "$(HOME)/.venvs/faster-qwen3-tts"
	"$(HOME)/.venvs/faster-qwen3-tts/bin/pip" install --upgrade pip
	"$(HOME)/.venvs/faster-qwen3-tts/bin/pip" install "faster-qwen3-tts[demo]"
	@echo "Provide a reference clip at $(HOME)/faster-qwen3-tts/ref_audio.wav and edit --ref-text in the unit file before enabling."
	mkdir -p "$(HOME)/.config/systemd/user"
	cp "$(CURDIR)/config/systemd/desktop-tts.service" "$(HOME)/.config/systemd/user/desktop-tts.service"
	systemctl --user daemon-reload
	@echo "Unit installed but not enabled -- run manually once first to confirm it starts cleanly:"
	@echo "  $(HOME)/.venvs/faster-qwen3-tts/bin/python $(HOME)/faster-qwen3-tts/examples/openai_server.py --ref-audio ... --ref-text ... --language English --port 8000"
	@echo "Then: systemctl --user enable --now desktop-tts.service"

# -- faster-whisper (turbo model) via speaches, native CUDA -----------------------
desktop-stt:
	@echo "Non-Docker launch command for speaches is unverified -- see TODO in config/systemd/desktop-stt.service."
	@echo "Confirm manually first (set up speaches/faster-whisper, a turbo model, device=cuda),"
	@echo "update desktop-stt.service's ExecStart to match, then re-run 'make desktop-stt'."
	mkdir -p "$(HOME)/.config/systemd/user"
	cp "$(CURDIR)/config/systemd/desktop-stt.service" "$(HOME)/.config/systemd/user/desktop-stt.service"
	systemctl --user daemon-reload
	@echo "Unit installed but not enabled until ExecStart is verified. Then: systemctl --user enable --now desktop-stt.service"
	@echo "wanda-box's openclaw.json media.models: replace the 'parakeet' entry with this endpoint over tailnet (desktop.mist-cat.ts.net:8001)."
