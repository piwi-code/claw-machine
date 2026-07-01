# Claw Machine — project context

A cozy 2D claw-machine **incremental game** built in **Godot 4.x / GDScript**.
Vibe reference: the claw machine in *Cats & Soup* — calm, collectible, tactile.
Built by a parent and their young daughter together, so changes should stay
small, readable, and quick to try.

## Stack & targets
- Engine: Godot 4.x, GDScript (not C#).
- Renderer: Compatibility (chosen for Android + future web export).
- Platforms: macOS, Windows, Android tablet. Most play-testing is on an Android
  tablet — keep export friction low and avoid desktop-only assumptions.

## Architecture (keep this shape)
- `data/game_data.gd` — global class `GameData`. PURE DATA only: prizes,
  upgrades, tuning constants. No logic. This is the "tweak the numbers" file
  the kid edits.
- `autoload/game_state.gd` — Autoload `GameState`. Single source of truth
  (coins, upgrade_levels, collection) + save/load to `user://save.json`.
  Emits signals (coins_changed, prize_won, grab_failed, upgrade_purchased).
- `claw/claw_machine.gd` — class `ClawMachine`. OLD idle-game grab logic.
  `attempt_grab()` rolls outcome, picks a weighted prize, awards coins via
  GameState. Being superseded by the physics claw below — see Pivot note.
- `main.gd` — TEMPORARY code-built test UI for the OLD idle game. Currently
  not the active scene (see Pivot note); kept around, not deleted.
- `tests/` — headless GDScript regression tests. No editor, no human, no UI;
  see "Testing" below.

### Physics claw (in progress — replacing the idle mechanic)
The game is pivoting from a dice-roll idle mechanic to a real physics-based
claw: move it left/right, drop it, and whether you actually grab a ball is
simulated (Godot 2D physics), not rolled. The dice-roll didn't disappear, it
moved — instead of rolling for grab *success*, it now rolls when *populating
the machine* with which prize each ball is (`GameState.pick_weighted_prize()`).
Being built in small slices:
- `claw/physics_playground.gd` (+ `.tscn`) — **Slices 1 & 2, done.** On-screen
  hold-left/hold-right + a big DROP button; real RigidBody2D balls with
  gravity/collision; kinematic "carry" grab (freeze + reparent under the claw
  head, no joints). Each ball is rolled a `prize_id` when it spawns. A grab
  pays out through `GameState` once the claw is fully retracted (see
  `ClawRig.collected` below) — for now that's the whole "delivery": the ball
  is removed and a fresh one spawns in its place. No return-home animation or
  chute yet. This is currently `project.godot`'s `run/main_scene`.
- `claw/claw_rig.gd` — class `ClawRig`. The carriage/arm/pincer state machine
  (IDLE / DIVING / CLOSING / RISING) and grab detection. Emits `grabbed`
  (caught something, still mid-air), `missed`, and `collected` (fully
  retracted with a ball — this is the "it's yours now" moment). Stays
  economy-agnostic on purpose — it doesn't know about prizes or coins, only
  physics; the listener decides what collecting means.
- `claw/prize_ball.gd` — class `PrizeBall`. Placeholder RigidBody2D circle;
  `prize_id` drives both its payout (`GameData.PRIZES`) and its color, so
  rarer prizes already look different even before real art exists.
- `GameState.pick_weighted_prize()` / `GameState.award_prize(prize_id)` —
  shared by both the old dice-roll (`ClawMachine.attempt_grab()`) and the
  physics claw, so "which prize" and "what winning one does" can't drift
  apart between the two mechanics.
- Physics tuning (speeds, drop depth, ball size/count) lives in
  `data/game_data.gd` under "CLAW PHYSICS (playground)", per the
  data-not-hard-coded convention.

**Planned direction** (not yet built): rarer/better prizes could be visually
distinct and physically harder to grab (heavier, smaller, more slippery), so
`grip_strength` becomes a real physical property of the claw rather than a
probability nudge. Also still open: the claw currently pays out balls in
place rather than returning "home" and dropping them down a chute (mentioned
as a likely future step, not built). Last item on the original list: retire
the old dice-roll `attempt_grab()` path once the physics path fully
replaces it as the shipped game mode.

## Conventions
- **Code-first, not editor-first.** Create nodes, connect signals, and define
  behaviour in scripts so the whole game is legible/editable from text.
- Logic never touches the UI directly — it emits a signal; the UI listens.
- Game balance lives in `game_data.gd` as data, never hard-coded in logic.
- New upgrade = add a data block in `game_data.gd`, then add a getter in
  `game_state.gd` that applies its effect.
- Keep scripts small and single-purpose.
- Save/load is non-negotiable and already wired — don't regress it.

## Testing
- `tests/run_headless.sh` runs every `tests/*_test.tscn` scene against a real
  Godot binary with `--headless` — no GUI, no manual clicking. It finds a
  Godot binary via `$GODOT`, then `godot4`/`godot` on PATH, then a cached copy
  in `tests/.godot-bin/` (gitignored), downloading one there if none exist.
- A test scene is a plain `Node2D` script: build the same physics setup the
  real game uses (reusing `GameData` constants, never re-hardcoding pit/ball
  numbers), drive it exactly like a player would (`ClawRig.start_drop()`,
  etc.), then `get_tree().quit(0)` on pass / `quit(1)` on fail. See
  `tests/grab_regression_test.gd` (raw `ClawRig` + `PrizeBall`) and
  `tests/collect_regression_test.gd` (loads the real `physics_playground.tscn`
  to exercise the production `GameState` wiring) for the two patterns.
- `run_headless.sh` runs every test under a throwaway `$HOME`, since Godot
  resolves `user://` (i.e. `save.json`) under `$HOME` for a plain build —
  any test touching `GameState` would otherwise read/overwrite your real
  save file.
- These tests catch physics/logic regressions (a grab that no longer reaches
  a ball, a script error, a crash). They do NOT tell you whether something
  feels good to play — that still needs a human with the real editor open.

## Roadmap (build one small, self-contained feature per session)
1. ~~Auto-claw~~ — superseded: the claw is now player-driven physics, not an
   auto-repeating `attempt_grab()` roll. See "Physics claw" above instead.
2. Offline progress: save already stores `last_played_unix`; award catch-up
   coins on load.
3. Collection album screen using `GameState.collection`.
4. ~~Real cozy art + claw-lowering animation~~ — the physics claw slices above
   are doing this now, incrementally, instead of one big art swap.
5. Coin-shower / particle juice on big payouts.
6. Prestige/reset layer (much later).

## Notes for the assistant
- Verify Godot 4.x API specifics against current docs rather than assuming.
- See `README.md` for setup steps; don't duplicate it here.
- **Cloud/web sessions have no Godot editor GUI and no pre-installed Godot
  binary.** You can still validate changes without the user: download the
  matching Linux Godot build (check `project.godot`'s `config/features` for
  the version, e.g. `4.7`) from GitHub releases, run
  `--headless --path . --import` once to build the class cache, then either
  smoke-test the real scene (`--headless --path . --quit-after N`, check
  stderr for `SCRIPT ERROR`/`ERROR`) or run `tests/run_headless.sh`. The
  downloaded binary is a build tool, not project content — don't commit it;
  either let it live in a scratch dir or in the gitignored
  `tests/.godot-bin/` the test runner already uses.
- What headless runs can't tell you: whether a change *feels* good (drop
  speed, grab fairness, "cozy-ness"). Flag those for the user to try locally
  with the real editor rather than declaring them done yourself.
- **Android deploy is already set up on the dev machine** (JDK 17, Android
  SDK cmdline-tools, export templates, debug keystore, `export_presets.cfg`)
  — see the "Deploying to an Android tablet" section in `README.md`. Use
  `scripts/deploy_android.sh` to build and reinstall on the tablet; don't
  redo the toolchain setup from scratch. `godot --headless --export-debug
  "Android" <path>` needs Project Settings' `textures/vram_compression/
  import_etc2_astc` enabled (already on) or it refuses to export.
