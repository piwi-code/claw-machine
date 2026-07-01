extends Node2D
## HEADLESS REGRESSION TEST — no editor, no human, no UI.
##
## Loads the real physics_playground scene (not a hand-built stand-in) and
## drives its actual claw, so this exercises the production
## "ClawRig.collected -> GameState.award_prize()" wiring directly instead of
## re-testing a copy of it. Removes every ball but one and forces that one's
## prize_id so the payout is exact and there's no jostling from other balls
## to make the grab flaky.
##
## tests/run_headless.sh runs every test under a throwaway $HOME, so this
## never reads or writes your real save file. Exits 0 on pass, 1 on
## fail/timeout.

const SETTLE_FRAMES := 90     # let the ball fall and land on the floor first
const TIMEOUT_FRAMES := 900   # safety net so a stuck state machine can't hang
const TARGET_PRIZE_ID := "dragon"

var _playground: Node2D
var _coins_before: int
var _collection_before: int
var _frame := 0
var _drop_triggered := false


func _ready() -> void:
	_playground = (load("res://claw/physics_playground.tscn") as PackedScene).instantiate()
	add_child(_playground)

	var balls_container: Node2D = _playground._balls_container
	var target_ball: PrizeBall = balls_container.get_child(0)
	for child in balls_container.get_children():
		if child != target_ball:
			child.queue_free()

	target_ball.prize_id = TARGET_PRIZE_ID
	target_ball.position = Vector2(0.0, GameData.PIT_HEIGHT - 40.0)  # claw starts centered at local x=0

	_coins_before = GameState.coins
	_collection_before = GameState.collection.get(TARGET_PRIZE_ID, 0)


func _physics_process(_delta: float) -> void:
	_frame += 1

	if _frame > TIMEOUT_FRAMES:
		_finish(false, "TIMEOUT: ball was never collected after %d frames" % TIMEOUT_FRAMES)
		return

	if not _drop_triggered:
		if _frame >= SETTLE_FRAMES:
			_drop_triggered = true
			_playground._claw.start_drop()
		return

	if GameState.collection.get(TARGET_PRIZE_ID, 0) > _collection_before:
		_check_result()


func _check_result() -> void:
	var expected_coins := _coins_before + int(round(
		GameData.PRIZES[TARGET_PRIZE_ID]["value"] * GameState.get_coin_multiplier()
	))
	if GameState.coins == expected_coins:
		_finish(true, "PASS: collecting a %s awarded %d coins and updated the collection" % [
			TARGET_PRIZE_ID, expected_coins - _coins_before
		])
	else:
		_finish(false, "FAIL: coins=%d expected=%d" % [GameState.coins, expected_coins])


func _finish(passed: bool, message: String) -> void:
	if passed:
		print(message)
	else:
		printerr(message)
	get_tree().quit(0 if passed else 1)
