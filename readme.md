# Claw Machine — MVP skeleton

A tiny, runnable starting point for a cozy claw-machine incremental game in
Godot 4 (GDScript). The full loop works on day one: **drop the claw → win a
prize → earn coins → buy an upgrade → progress is saved.**

## Files

```
data/game_data.gd      <- the "tweak the numbers" file (prizes, upgrades, tuning)
autoload/game_state.gd <- single source of truth + save/load (an Autoload)
claw/claw_machine.gd   <- the core grab logic
main.gd                <- a throwaway test UI so it runs immediately
```

## Setup (about 5 minutes)

1. Create a new **Godot 4.x** project. The **Compatibility** renderer is the
   safe pick — it's the friendliest for Android tablets and for web later.
2. Copy the four files above into your project, keeping the folder layout.
3. Register the autoload: **Project → Project Settings → Globals** (the
   *Autoload* tab). Set the path to `res://autoload/game_state.gd`, set the
   node name to **`GameState`** (exact spelling matters), and click Add.
   - You do **not** need to register `GameData` — `class_name GameData` makes
     it globally available on its own.
4. Make a main scene: **Scene → New Scene → User Interface** (root is a
   `Control`). Attach `main.gd` to that root node. Save it as `main.tscn`.
5. Set it as the run target: **Project → Project Settings → Application → Run →
   Main Scene → `main.tscn`**.
6. Press **Play**. Drop the claw!

## The data flow (worth holding in your head)

```
main.gd  --calls-->  claw.attempt_grab()
claw_machine.gd  --updates-->  GameState (coins, collection)
GameState  --emits signals-->  main.gd updates the labels
GameState  --writes-->  user://save.json
```

Logic never reaches into the UI; it just emits a signal. That separation is
what lets you (or an AI) rewrite the whole look without touching the rules.

## Where your daughter plugs in

- **`game_data.gd` — the prizes.** She draws the plushies; swap each `"color"`
  for the path to her artwork, and let her name them.
- **`game_data.gd` — the numbers.** "Make the claw grabbier" = raise
  `BASE_GRAB_CHANCE`. "Make the dragon rarer" = lower its `weight`. Press Play,
  see the change. Safe to experiment — this file can't break the plumbing.

## The natural next features (each is a small, self-contained session)

- **Auto-claw (your first idle mechanic):** add a `Timer` that calls
  `attempt_grab()` on its own; gate it behind a new upgrade in `game_data.gd`.
- **Offline progress:** the save already stores `last_played_unix`. On load,
  compare it to now and award some catch-up coins.
- **Collection album:** you already track `GameState.collection` — give it a
  real screen with the artwork.
- **The coin tornado:** wrap `add_coins` payouts in a particle burst once the
  numbers get big. (Save this kind of juice for after the systems feel right.)
- **Prestige/reset layer:** much later.

## Deploying to an Android tablet

One-time host setup (already done on this machine, July 2026):

- JDK 17 (`brew install openjdk@17`) and the Android SDK cmdline-tools
  (`brew install --cask android-commandlinetools`), with `platform-tools`,
  `build-tools;35.0.1`, and `platforms;android-35` installed via `sdkmanager`.
- The standalone `godot` cask (not `godot-mono`) matching this project's
  engine version (4.7) — the project has no C#, so the plain build avoids
  needing a .NET SDK just to export.
- A debug keystore and the Android/Java SDK paths registered in Godot's
  global Editor Settings (`export/android/*`), and an `Android` export
  preset checked into [`export_presets.cfg`](export_presets.cfg).
- `~/.zshrc` exports `ANDROID_HOME` and puts `adb` on `PATH` — open a new
  terminal (or `source ~/.zshrc`) to pick that up. `JAVA_HOME` is
  deliberately *not* set globally: Godot's own Editor Settings point straight
  at the Homebrew JDK for exporting/signing, so a shell-wide `JAVA_HOME`
  isn't needed — and would otherwise override tools like `mise` that manage a
  different Java version per project.

To build and install on the tablet:

1. On the tablet: Settings → About tablet → tap **Build number** 7 times to
   unlock Developer options, then Developer options → **USB debugging** on.
2. Plug the tablet in over USB and accept the "Allow USB debugging" prompt
   (or use `adb connect <tablet-ip>:5555` for wireless debugging instead).
3. Run [`scripts/deploy_android.sh`](scripts/deploy_android.sh) from the
   project root. Add `--launch` to also start the app, or `--logcat` to
   start it and stream its log output.

Re-run that script any time you want to try a change on the tablet — it
re-exports a fresh debug APK and reinstalls it (`adb install -r`, so your
save data on the device is preserved between installs).

## Building for the web

A `Web` export preset is also checked into [`export_presets.cfg`](export_presets.cfg)
(no extra host setup needed — the web export templates came bundled in the
same download used for Android). Godot's web export won't run from a
`file://` URL, so it needs to be served over plain HTTP:

```
scripts/build_web.sh --serve
```

Then open `http://localhost:8060` in a browser. Leave off `--serve` to just
produce `build/web/index.html` without starting a server (e.g. if you're
serving it another way, or deploying the `build/web/` folder somewhere).
