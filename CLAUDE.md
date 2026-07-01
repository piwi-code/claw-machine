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

### Physics claw (in progress — replacing the idle mechanic)
The game is pivoting from a dice-roll idle mechanic to a real physics-based
claw: move it left/right, drop it, and whether you actually grab a ball is
simulated (Godot 2D physics), not rolled. Being built in small slices:
- `claw/physics_playground.gd` (+ `.tscn`) — **Slice 1, done.** Pure movement
  and grab feel: on-screen hold-left/hold-right + a big DROP button, real
  RigidBody2D balls with gravity/collision, kinematic "carry" grab (freeze +
  reparent under the claw head, no joints). Deliberately has NO scoring —
  no coins, no prizes, no GameState calls. This is currently `project.godot`'s
  `run/main_scene`, so pressing Play loads it instead of the old idle UI.
- `claw/claw_rig.gd` — class `ClawRig`. The carriage/arm/pincer state machine
  (IDLE / DIVING / CLOSING / RISING) and grab detection. Emits `grabbed`,
  `missed`, `released` signals — same "logic emits, UI listens" convention.
- `claw/prize_ball.gd` — class `PrizeBall`. Placeholder RigidBody2D circle
  (flat-color `_draw()`), no art yet.
- Physics tuning (speeds, drop depth, ball size/count) lives in
  `data/game_data.gd` under "CLAW PHYSICS (playground)", per the
  data-not-hard-coded convention.

**Planned direction** (not yet built): the dice-roll doesn't disappear, it
moves — instead of rolling for grab *success*, it rolls when *populating the
machine* with which balls are in the pit. Rarer/better prizes could be
visually distinct and physically harder to grab (heavier, smaller, more
slippery), so `grip_strength` becomes a real physical property of the claw
rather than a probability nudge. Next slices (in rough order): (a) give balls
a `prize_id` + distinct look/physics per rarity, (b) wire a successful grab
into `GameState`/coins/collection, (c) retire the old dice-roll
`attempt_grab()` path once the physics path fully replaces it.

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
