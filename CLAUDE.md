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
- `menu/main_menu.gd` (+ `.tscn`) — the game's entry point, `project.godot`'s
  `run/main_scene`. Continue vs New Game: Continue only shows when
  `GameState.has_save()` is true; New Game confirms (it's destructive) before
  calling `GameState.reset_game()` and loading the physics playground. Also
  has an Exit button, hidden on web (`OS.has_feature("web")`) since closing
  a browser tab isn't the game's call to make.
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
  chute yet. Reached from `menu/main_menu.gd` (Continue or New Game), which is
  now `project.godot`'s `run/main_scene`.
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

Planned next steps for this mechanic (grip_strength as a physical property,
chute/return-home delivery, retiring the old dice-roll path) are tracked in
`ROADMAP.md`, not here.

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

## Roadmap

See `ROADMAP.md` — don't duplicate its list here, keep it updated there
instead (strike out items as they land, the way it already does for the
auto-claw/art items superseded by the physics claw).

## Notes for the assistant
- Verify Godot 4.x API specifics against current docs rather than assuming.
- See `README.md` for setup steps; don't duplicate it here.
- **Cloud/web sessions have no Godot editor GUI and no pre-installed Godot
  binary — but you can download one.** Use Godot's official SourceForge
  mirror (`downloads.sourceforge.net/project/godot-engine.mirror/<version>/
  ...`, checksums in that folder's `SHA512-SUMS.txt`): `sourceforge.net` is
  on Claude Code's default "Trusted" network allowlist, so it works even in
  a stock environment. Two hosts that look more official do NOT work, so
  don't burn time on them: GitHub Releases URLs 403 because `github.com`
  traffic goes through a separate repo-scoped proxy (independent of the
  Network access setting; adding `godotengine/godot` as a source is
  cross-owner and rejected, and forks don't carry release assets), and
  `downloads.tuxfamily.org` — Godot's old host, cited in older docs — is
  defunct (503s). Match the version to `project.godot`'s `config/features`
  (e.g. `4.7` → `4.7-stable`), then run `--headless --path . --import` once
  to build the class cache, then smoke-test the real scene
  (`--headless --path . --quit-after N`, check stderr for `SCRIPT ERROR`/
  `ERROR`) or run `tests/run_headless.sh` (its auto-download uses this same
  mirror). The binary is a build tool, not project content — don't commit
  it; keep it in a scratch dir or the gitignored `tests/.godot-bin/`.
- **You can SEE and drive the web build yourself**: grab the export
  templates from the same mirror folder (`*_export_templates.tpz` — 1.3 GB,
  but you only need the `templates/web_*` members; `unzip -j` them into
  `~/.local/share/godot/export_templates/<version>.stable/`), export with
  `scripts/build_web.sh`, serve it, and drive it with Playwright
  (`playwright-core` + the pre-installed Chromium; take screenshots, click
  buttons by coordinates). The Web preset has `thread_support=false`, so a
  plain `python3 -m http.server` works — no COOP/COEP headers needed. This
  catches "wrong scene loads"/"button missing" wiring bugs that headless
  tests can't, though game *feel* still needs a human (see below).
- **A dedicated cloud environment can have Godot pre-installed instead of
  downloaded per-session.** `scripts/godot_cloud_setup.sh` is the checked-in
  copy of a Setup script to paste into that environment's config (Setup
  scripts are configured in the environment dialog, not a repo file, and
  their output is cached as an environment snapshot, unlike a SessionStart
  hook's — so the ~1.4 GB of downloads happens once, not per session). It
  installs the editor binary to `/usr/local/bin/godot4` plus the web export
  templates, from the SourceForge mirror above — on the default Trusted
  allowlist, so the environment needs no custom Allowed domains.
  `.claude/hooks/session-start.sh` (registered in `.claude/settings.json`)
  is the complementary SessionStart hook: it doesn't install anything
  itself, just reports whether a Godot binary is already on PATH or cached
  under `tests/.godot-bin/`, so a missing binary shows up as a clear message
  at session start instead of a confusing failure deep in some later
  command.
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
- **A `Web` export preset also exists** in `export_presets.cfg` (see
  "Building for the web" in `README.md`) — no extra host setup needed, the
  web export templates came bundled with the Android ones. Use
  `scripts/build_web.sh --serve` to export and serve it locally; it must be
  loaded over `http://`, not `file://`. This is also the only way you (the
  assistant) can actually *see* the game render and interact with it
  yourself — via the Claude Preview tools pointed at the served build —
  since you have no physical Android tablet. Useful for visually verifying
  UI/layout changes before asking the user to redeploy to their tablet.
- **Control nodes anchored under a `Node2D` scene root need `top_level =
  true`** to anchor against the real viewport — otherwise `CanvasItem`'s
  stub `get_anchorable_rect()` (which `Node2D` doesn't override) collapses
  every anchor preset to `(0, 0)`. Learned the hard way positioning
  `physics_playground.gd`'s on-screen buttons; see that file's `_build_ui()`
  comments for the full explanation, including a second gotcha where
  `set_anchors_and_offsets_preset()`'s `MINSIZE` mode reads a `Button`'s
  *intrinsic* text size rather than its `custom_minimum_size`.
