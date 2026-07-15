extends Node2D
## HEADLESS REGRESSION TEST — the timed claw run + shop screen wiring.
##
## Loads the real physics_playground scene, shrinks the remaining run time to
## a fraction of a second (so the test doesn't sit through the full
## GameData.RUN_SECONDS in real time — headless still runs in real time), and
## asserts the run ends on its own with the last-run summary landing in
## GameState. Then instantiates the real shop screen, so a script error there
## fails this test instead of only showing up when a human plays through.
##
## Quits before the playground's return-to-shop pause fires: that
## change_scene_to_file() would replace this very test scene.

const TIMEOUT_FRAMES := 300   # safety net (~5s); the shrunk timer needs ~15

var _playground: Node2D
var _frame := 0
var _shop: Control = null


func _ready() -> void:
	GameState.last_run_coins = -1
	_playground = (load("res://claw/physics_playground.tscn") as PackedScene).instantiate()
	add_child(_playground)
	_playground._time_left = 0.2


func _physics_process(_delta: float) -> void:
	_frame += 1

	if _frame > TIMEOUT_FRAMES:
		_finish(false, "TIMEOUT: run never ended after the timer expired")
		return

	if _shop != null:
		# Shop survived a frame after _ready() without a script error.
		_finish(true, "PASS: run ended by timer (last_run_coins=0) and the shop screen loads")
		return

	if _playground._phase != _playground.RunPhase.RUN_OVER:
		return

	# The run is over. Nothing was grabbed, so the recorded run must be +0.
	if GameState.last_run_coins != 0:
		_finish(false, "FAIL: last_run_coins=%d, expected 0 for a run with no grabs" % GameState.last_run_coins)
		return

	_shop = (load("res://shop/shop_screen.tscn") as PackedScene).instantiate()
	add_child(_shop)


func _finish(passed: bool, message: String) -> void:
	if passed:
		print(message)
	else:
		printerr(message)
	get_tree().quit(0 if passed else 1)
