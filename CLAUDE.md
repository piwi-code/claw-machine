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
- `claw/claw_machine.gd` — class `ClawMachine`. Core grab logic. `attempt_grab()`
  rolls outcome, picks a weighted prize, awards coins via GameState.
- `main.gd` — TEMPORARY code-built test UI. Disposable; replace with real scenes.

## Conventions
- **Code-first, not editor-first.** Create nodes, connect signals, and define
  behaviour in scripts so the whole game is legible/editable from text.
- Logic never touches the UI directly — it emits a signal; the UI listens.
- Game balance lives in `game_data.gd` as data, never hard-coded in logic.
- New upgrade = add a data block in `game_data.gd`, then add a getter in
  `game_state.gd` that applies its effect.
- Keep scripts small and single-purpose.
- Save/load is non-negotiable and already wired — don't regress it.

## Roadmap (build one small, self-contained feature per session)
1. Auto-claw: a Timer that calls `attempt_grab()`, gated behind a new upgrade.
2. Offline progress: save already stores `last_played_unix`; award catch-up
   coins on load.
3. Collection album screen using `GameState.collection`.
4. Real cozy art + claw-lowering animation (replaces `main.gd`).
5. Coin-shower / particle juice on big payouts.
6. Prestige/reset layer (much later).

## Notes for the assistant
- Verify Godot 4.x API specifics against current docs rather than assuming.
- See `README.md` for setup steps; don't duplicate it here.
