#!/bin/bash
# Paste this into a Claude Code cloud environment's "Setup script" field
# (open the environment for editing > Setup script). It is NOT run
# automatically by anything in this repo — environment setup scripts live in
# Anthropic's environment config, not the repo — this file is just the
# checked-in source of truth to copy from, so it's versioned and reviewable
# instead of living only in a UI text box.
#
# Requires the environment's Network access set to Custom, with
# downloads.tuxfamily.org in Allowed domains (Godot's real download host —
# github.com release downloads don't work from a cloud session, since GitHub
# traffic goes through a separate, repo-scoped proxy independent of the
# Network access domain list; see CLAUDE.md).
#
# Installs the Godot editor binary to /usr/local/bin/godot4 (so
# tests/run_headless.sh and scripts/build_web.sh find it on PATH with no
# extra config) and the matching export templates, so `--export-debug "Web"`
# works too. Runs the two downloads in parallel to help stay under the
# environment's ~5 minute setup script budget. Keep GODOT_VERSION in sync
# with project.godot's config/features.
set -euo pipefail

GODOT_VERSION="4.7-stable"
TEMPLATE_DIR="4.7.stable"   # Godot's own <version>.<status> export-templates folder naming
BASE_URL="https://downloads.tuxfamily.org/godotengine/4.7"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

(
	curl -fsSL -o "$TMP/godot.zip" "$BASE_URL/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
	unzip -oq "$TMP/godot.zip" -d "$TMP"
	install -m 755 "$TMP/Godot_v${GODOT_VERSION}_linux.x86_64" /usr/local/bin/godot4
) &
install_bin_pid=$!

(
	curl -fsSL -o "$TMP/templates.tpz" "$BASE_URL/Godot_v${GODOT_VERSION}_export_templates.tpz"
	mkdir -p "$TMP/templates_extract"
	unzip -oq "$TMP/templates.tpz" -d "$TMP/templates_extract"
	mkdir -p "$HOME/.local/share/godot/export_templates/$TEMPLATE_DIR"
	mv "$TMP/templates_extract/templates/"* "$HOME/.local/share/godot/export_templates/$TEMPLATE_DIR/"
) &
install_templates_pid=$!

wait "$install_bin_pid"
wait "$install_templates_pid"

godot4 --version
