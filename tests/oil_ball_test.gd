extends Node2D
## HEADLESS REGRESSION TEST — a BLACK "Oil Ball" grab must smear the glass.
##
## Loads the real physics_playground, forces the only ball to the black
## (effect="oil") prize, grabs it via the production ClawRig.collected wiring,
## and checks the oil overlay recorded a splat AND the coins were still paid.
## Guards the data-driven effect hook in physics_playground._on_ball_collected.
##
## tests/run_headless.sh runs every test under a throwaway $HOME, so this never
## touches your real save file. Exits 0 on pass, 1 on fail/timeout.

const SETTLE_FRAMES := 90     # let the ball fall and land first
const TIMEOUT_FRAMES := 900   # safety net so a stuck state machine can't hang
const TARGET_PRIZE_ID := "black"

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
	target_ball.position = Vector2(0.0, GameData.PIT_HEIGHT - 40.0)  # under the centered claw

	_coins_before = GameState.coins
	_collection_before = GameState.collection.get(TARGET_PRIZE_ID, 0)


func _physics_process(_delta: float) -> void:
	_frame += 1
	if _frame > TIMEOUT_FRAMES:
		_finish(false, "TIMEOUT: oil ball never collected after %d frames" % TIMEOUT_FRAMES)
		return

	if not _drop_triggered:
		if _frame >= SETTLE_FRAMES:
			_drop_triggered = true
			_playground._claw.start_drop()
		return

	if GameState.collection.get(TARGET_PRIZE_ID, 0) > _collection_before:
		_check_result()


func _check_result() -> void:
	var oil: OilOverlay = _playground._oil
	if oil == null:
		_finish(false, "FAIL: no oil overlay on the playground")
		return
	if oil._splats < 1:
		_finish(false, "FAIL: collecting the oil ball did not smear the glass (_splats=%d)" % oil._splats)
		return
	var expected_coins := _coins_before + int(round(
		GameData.PRIZES[TARGET_PRIZE_ID]["value"] * GameState.get_coin_multiplier()
	))
	if GameState.coins != expected_coins:
		_finish(false, "FAIL: coins=%d expected=%d" % [GameState.coins, expected_coins])
		return
	_finish(true, "PASS: oil ball smeared the glass (_splats=%d) and paid %d coins" % [
		oil._splats, expected_coins - _coins_before])


func _finish(passed: bool, message: String) -> void:
	if passed:
		print(message)
	else:
		printerr(message)
	get_tree().quit(0 if passed else 1)
