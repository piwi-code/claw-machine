#!/usr/bin/env bash
# Builds a debug APK from the "Android" export preset and installs it on a
# connected tablet over adb (USB or `adb connect` for wireless debugging).
# Meant to be re-run every time you want to try a change on the tablet.
#
# Usage:
#   scripts/deploy_android.sh            # export + install
#   scripts/deploy_android.sh --launch   # export + install + start the app
#   scripts/deploy_android.sh --logcat   # also stream the app's logcat after launch
#
# One-time setup (JDK 17, Android SDK cmdline-tools, export templates, debug
# keystore, editor SDK paths) is not done by this script — see the project
# README for that. This script only assumes the toolchain already works.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APK_PATH="$PROJECT_DIR/build/android/claw-machine.apk"

LAUNCH=0
LOGCAT=0
for arg in "$@"; do
	case "$arg" in
	--launch) LAUNCH=1 ;;
	--logcat) LAUNCH=1; LOGCAT=1 ;;
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

if command -v adb >/dev/null 2>&1; then
	ADB_BIN="$(command -v adb)"
elif [ -x "${ANDROID_HOME:-}/platform-tools/adb" ]; then
	ADB_BIN="$ANDROID_HOME/platform-tools/adb"
else
	echo "No adb found (checked PATH and \$ANDROID_HOME/platform-tools). Install it with:" >&2
	echo "  brew install --cask android-commandlinetools" >&2
	exit 1
fi

PACKAGE="$(sed -n 's/^package\/unique_name="\(.*\)"$/\1/p' "$PROJECT_DIR/export_presets.cfg" | head -1)"

mkdir -p "$(dirname "$APK_PATH")"

echo "Using Godot binary: $GODOT_BIN"
echo "Exporting debug APK to $APK_PATH ..."
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-debug "Android" "$APK_PATH"

if [ ! -f "$APK_PATH" ]; then
	echo "Export did not produce an APK — check the Godot output above." >&2
	exit 1
fi

device_count="$("$ADB_BIN" devices | grep -c $'\tdevice$' || true)"
if [ "$device_count" -eq 0 ]; then
	echo "No device detected by adb. On the tablet: Settings > About tablet > tap" >&2
	echo "'Build number' 7x to enable Developer options, then Developer options >" >&2
	echo "USB debugging. Plug in over USB (or 'adb connect <ip>:5555' for wireless)" >&2
	echo "and accept the 'Allow USB debugging' prompt on the tablet." >&2
	exit 1
fi

echo "Installing on device ..."
"$ADB_BIN" install -r "$APK_PATH"

if [ "$LAUNCH" -eq 1 ]; then
	echo "Launching $PACKAGE ..."
	"$ADB_BIN" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null
fi

if [ "$LOGCAT" -eq 1 ]; then
	echo "Streaming logcat (Ctrl+C to stop) ..."
	"$ADB_BIN" logcat --pid="$("$ADB_BIN" shell pidof -s "$PACKAGE")"
fi
