#!/bin/bash
# SESSION START HOOK — cloud sessions only (see CLAUDE_CODE_REMOTE check
# below). Doesn't install Godot itself: that's the dedicated cloud
# environment's own Setup script (scripts/godot_cloud_setup.sh is the
# checked-in copy of it), which benefits from environment-level caching.
# This hook just reports what it finds so a missing Godot binary shows up
# as a clear message at session start instead of a confusing failure deep
# inside some later command.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
	exit 0
fi

GODOT_VERSION="4.7-stable"
CACHED_BIN="$CLAUDE_PROJECT_DIR/tests/.godot-bin/Godot_v${GODOT_VERSION}_linux.x86_64"

if command -v godot4 >/dev/null 2>&1; then
	echo "Godot found on PATH: $(command -v godot4)"
elif command -v godot >/dev/null 2>&1; then
	echo "Godot found on PATH: $(command -v godot)"
elif [ -x "$CACHED_BIN" ]; then
	echo "export GODOT=\"$CACHED_BIN\"" >>"$CLAUDE_ENV_FILE"
	echo "Godot found in tests/.godot-bin cache: $CACHED_BIN"
else
	echo "No Godot binary found on PATH or in tests/.godot-bin." >&2
	echo "If this environment has scripts/godot_cloud_setup.sh configured as its Setup script, check that script's output for download errors." >&2
	echo "Otherwise tests/run_headless.sh and scripts/build_web.sh will try to download Godot themselves, which needs network access to Godot's release host." >&2
fi

exit 0
