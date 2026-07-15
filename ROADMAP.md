# Roadmap

Build one small, self-contained feature per session.

1. ~~Auto-claw~~ — superseded: the claw is now player-driven physics, not an
   auto-repeating `attempt_grab()` roll. See the physics claw notes in
   `CLAUDE.md` instead.
2. Offline progress: save already stores `last_played_unix`; award catch-up
   coins on load.
3. Collection album screen using `GameState.collection`.
4. ~~Real cozy art + claw-lowering animation~~ — the physics claw slices
   are doing this now, incrementally, instead of one big art swap.
5. Coin-shower / particle juice on big payouts.
6. Prestige/reset layer (much later).
7. `grip_strength` as a real physical property: rarer/better prizes are
   visually distinct *and* physically harder to grab (heavier, smaller, more
   slippery), instead of a probability nudge.
8. Return-home + chute delivery: the claw currently pays out a grabbed ball
   in place; it should instead carry it back "home" and drop it down a chute.
9. Retire the old dice-roll `claw/claw_machine.gd` (`attempt_grab()`) path
   once the physics claw fully replaces it as the shipped game mode.
10. Shop power-ups that bend the claw run: more time (`RUN_SECONDS`), more
    balls (`BALL_COUNT`), and prize-odds boosts (base weights + purchased
    multipliers deciding what fills the pit). The shop screen exists and the
    run reads those numbers from `game_data.gd`, so each power-up is "add an
    upgrade block + a GameState getter + read it where the run starts".
