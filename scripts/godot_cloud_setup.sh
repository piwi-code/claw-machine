#!/bin/bash
# Paste this into a Claude Code cloud environment's "Setup script" field
# (open the environment for editing > Setup script). It is NOT run
# automatically by anything in this repo — environment setup scripts live in
# Anthropic's environment config, not the repo — this file is just the
# checked-in source of truth to copy from, so it's versioned and reviewable
# instead of living only in a UI text box.
#
# Downloads from Godot's official SourceForge mirror
# (sourceforge.net/projects/godot-engine.mirror). That host is on Claude
# Code's DEFAULT "Trusted" network allowlist, so this works without any
# custom Allowed domains. (Don't switch it to github.com releases — GitHub
# traffic goes through a separate repo-scoped proxy, so godotengine release
# downloads 403 regardless of network settings. downloads.tuxfamily.org,
# Godot's old host, is defunct — it 503s; see CLAUDE.md.)
#
# Installs the Godot editor binary to /usr/local/bin/godot4 (so
# tests/run_headless.sh and scripts/build_web.sh find it on PATH with no
# extra config) and, from the 1.3 GB all-platform template pack, just the
# web export templates, so `--export-debug "Web"` works too. Keep
# GODOT_VERSION in sync with project.godot's config/features.
set -euo pipefail

GODOT_VERSION="4.7-stable"
TEMPLATE_DIR="4.7.stable"   # Godot's own <version>.<status> export-templates folder naming
BASE_URL="https://downloads.sourceforge.net/project/godot-engine.mirror/${GODOT_VERSION}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Fetch the checksum list first, then verify both downloads against it.
curl -fsSL -o "$TMP/SHA512-SUMS.txt" "$BASE_URL/SHA512-SUMS.txt"

(
	curl -fsSL -o "$TMP/Godot_v${GODOT_VERSION}_linux.x86_64.zip" "$BASE_URL/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
) &
bin_pid=$!

(
	curl -fsSL -o "$TMP/Godot_v${GODOT_VERSION}_export_templates.tpz" "$BASE_URL/Godot_v${GODOT_VERSION}_export_templates.tpz"
) &
templates_pid=$!

wait "$bin_pid"
wait "$templates_pid"

cd "$TMP"
# Match the exact filenames: SHA512-SUMS.txt also lists the mono builds
# (Godot_v4.7-stable_mono_export_templates.tpz), which a loose substring
# match pulls in — and sha512sum -c then fails on the never-downloaded file.
grep -E "  Godot_v${GODOT_VERSION}_(linux\.x86_64\.zip|export_templates\.tpz)$" SHA512-SUMS.txt | sha512sum -c -

unzip -oq "Godot_v${GODOT_VERSION}_linux.x86_64.zip"
install -m 755 "Godot_v${GODOT_VERSION}_linux.x86_64" /usr/local/bin/godot4

# The .tpz is a zip of templates for every platform; extract only the web
# ones (the whole pack unpacked is huge and Android/iOS/desktop templates
# aren't useful in a cloud session).
mkdir -p "$HOME/.local/share/godot/export_templates/$TEMPLATE_DIR"
unzip -oqj "Godot_v${GODOT_VERSION}_export_templates.tpz" "templates/web_*" \
	-d "$HOME/.local/share/godot/export_templates/$TEMPLATE_DIR"

godot4 --version
