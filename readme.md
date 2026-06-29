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
