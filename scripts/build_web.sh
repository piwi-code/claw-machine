#!/usr/bin/env bash
# Builds a debug web (HTML5) export from the "Web" preset and serves it over
# a plain local HTTP server — Godot's web export won't run from a file://
# URL, it needs to be fetched over http(s).
#
# Usage:
#   scripts/build_web.sh          # export only
#   scripts/build_web.sh --serve  # export, then serve on http://localhost:8060
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$PROJECT_DIR/build/web"
PORT=8060

SERVE=0
for arg in "$@"; do
	case "$arg" in
	--serve) SERVE=1 ;;
	*)
		echo "Unknown argument: $arg" >&2
		exit 1
		;;
	esac
done

if [ -n "${GODOT:-}" ]; then
	GODOT_BIN="$GODOT"
elif command -v godot4 >/dev/null 2>&1; then
	GODOT_BIN="$(command -v godot4)"
elif command -v godot >/dev/null 2>&1; then
	GODOT_BIN="$(command -v godot)"
else
	echo "No Godot binary found (checked \$GODOT, godot4, godot). Install it with:" >&2
	echo "  brew install --cask godot" >&2
	exit 1
fi

mkdir -p "$OUT_DIR"

echo "Using Godot binary: $GODOT_BIN"
echo "Exporting debug web build to $OUT_DIR ..."
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-debug "Web" "$OUT_DIR/index.html"

if [ ! -f "$OUT_DIR/index.html" ]; then
	echo "Export did not produce index.html — check the Godot output above." >&2
	exit 1
fi

if [ "$SERVE" -eq 1 ]; then
	echo "Serving on http://localhost:$PORT ..."
	python3 -m http.server "$PORT" --directory "$OUT_DIR"
fi
