#!/usr/bin/env bash
# Runs every headless test scene in tests/*_test.tscn against a real Godot
# binary — no editor GUI, no manual playtesting required.
#
# Uses, in order: $GODOT if set, then `godot4`/`godot` on PATH, then a copy
# cached under tests/.godot-bin/ (gitignored), downloading it there if none
# of those exist yet. That makes this work the same on a fresh clone, in CI,
# or in a cloud session with no Godot pre-installed.
set -euo pipefail

GODOT_VERSION="4.7-stable"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CACHE_DIR="$SCRIPT_DIR/.godot-bin"
CACHED_BIN="$CACHE_DIR/Godot_v${GODOT_VERSION}_linux.x86_64"

if [ -n "${GODOT:-}" ]; then
	GODOT_BIN="$GODOT"
elif command -v godot4 >/dev/null 2>&1; then
	GODOT_BIN="$(command -v godot4)"
elif command -v godot >/dev/null 2>&1; then
	GODOT_BIN="$(command -v godot)"
elif [ -x "$CACHED_BIN" ]; then
	GODOT_BIN="$CACHED_BIN"
else
	echo "No Godot found; downloading $GODOT_VERSION into $CACHE_DIR ..."
	mkdir -p "$CACHE_DIR"
	curl -sSL -o "$CACHE_DIR/godot.zip" \
		"https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
	unzip -oq "$CACHE_DIR/godot.zip" -d "$CACHE_DIR"
	chmod +x "$CACHED_BIN"
	GODOT_BIN="$CACHED_BIN"
fi

echo "Using Godot binary: $GODOT_BIN"
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --import

status=0
shopt -s nullglob
test_scenes=("$SCRIPT_DIR"/*_test.tscn)
shopt -u nullglob

if [ ${#test_scenes[@]} -eq 0 ]; then
	echo "No test scenes found in $SCRIPT_DIR (looking for *_test.tscn)."
	exit 1
fi

for scene in "${test_scenes[@]}"; do
	name="$(basename "$scene")"
	echo "--- $name ---"
	if "$GODOT_BIN" --headless --path "$PROJECT_DIR" "res://tests/$name"; then
		echo "$name: OK"
	else
		echo "$name: FAILED"
		status=1
	fi
done

exit $status
