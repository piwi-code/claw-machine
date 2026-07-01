# Claw Machine

A cozy 2D physics-based claw machine game, built in Godot 4 (GDScript) by a
parent and their young daughter. Move the claw, drop it, and see what you
grab — real physics decide whether you catch a prize, not a dice roll.

**[Play it in your browser](https://piwi-code.github.io/claw-machine/)**

## Running it locally

Requires the [Godot 4.7](https://godotengine.org/download) editor. Clone the
repo, open `project.godot`, press **Play**.

Controls: hold the on-screen `<`/`>` buttons (or arrow keys) to move the
claw, then press **DROP** (or Space) to dive for a prize.

See [`CLAUDE.md`](CLAUDE.md) for the project's architecture and how to run
the headless regression test suite.

## Deploying to an Android device

One-time host setup:

- Install JDK 17 and the Android SDK command-line tools — e.g. on macOS via
  Homebrew: `brew install openjdk@17` and
  `brew install --cask android-commandlinetools`. Then use that install's
  `sdkmanager` to fetch `platform-tools`, `build-tools;35.0.1`, and
  `platforms;android-35`.
- Install a Godot 4.7 editor build matching this project. Use the standard
  (non-Mono) build — this project has no C#, so a .NET-enabled build isn't
  needed just to export.
- In the editor's Editor Settings, point `export/android/java_sdk_path` and
  `export/android/android_sdk_path` at the JDK and SDK installed above.
  Godot will generate a debug keystore automatically the first time you
  export, or you can point `export/android/debug_keystore` at one you
  already have.
- Put `adb` (from the SDK's `platform-tools`) on your `PATH`. There's no
  need to also put the JDK on `PATH`/`JAVA_HOME` globally — Godot reads the
  Editor Settings path above directly, which avoids clobbering a per-project
  Java version manager (`mise`, `asdf`, etc.) you might already use.

To build and install on a device:

1. On the device: Settings → About → tap **Build number** 7 times to unlock
   Developer options, then Developer options → **USB debugging** on.
2. Plug it in over USB and accept the "Allow USB debugging" prompt (or use
   `adb connect <device-ip>:5555` for wireless debugging instead).
3. Run [`scripts/deploy_android.sh`](scripts/deploy_android.sh) from the
   project root. Add `--launch` to also start the app, or `--logcat` to
   start it and stream its log output.

Re-run that script any time you want to try a change on the device — it
re-exports a fresh debug APK and reinstalls it (`adb install -r`, so save
data on the device is preserved between installs).

## Building for the web

A `Web` export preset is checked into [`export_presets.cfg`](export_presets.cfg)
(no extra host setup needed beyond the Godot editor itself — the web export
templates come bundled with the same download used for Android). Godot's web
export won't run from a `file://` URL, so it needs to be served over plain
HTTP:

```
scripts/build_web.sh --serve
```

Then open `http://localhost:8060` in a browser. Leave off `--serve` to just
produce `build/web/index.html` without starting a server (e.g. if you're
serving it another way, or deploying the `build/web/` folder somewhere). The
hosted version at the link above is built and deployed automatically by
[`.github/workflows/deploy-pages.yml`](.github/workflows/deploy-pages.yml) on
every push to `main`.

## Roadmap

See [`ROADMAP.md`](ROADMAP.md) for what's planned next.

## License

Code is licensed under the [MIT License](LICENSE). That covers the GDScript
and project files — it does not cover any original art, audio, or other
creative assets added to the project (e.g. under `data/` or wherever hand-
drawn prize artwork ends up), which remain all-rights-reserved unless stated
otherwise.
