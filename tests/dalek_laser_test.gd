extends Node2D
## HEADLESS REGRESSION TEST — no editor, no human, no UI.
##
## Loads the real physics_playground scene and checks the Dalek's party trick:
## grabbing a "dalek" ball fires laser pulses that destroy GameData.DALEK_LASER_COUNT
## other balls on the way up. Thins the pit down to one Dalek (parked under the
## claw) plus a handful of spread-out targets, so the grab is deterministic and
## there are strictly more targets than lasers.
##
## tests/run_headless.sh runs every test under a throwaway $HOME, so this never
## touches your real save file. Exits 0 on pass, 1 on fail/timeout.

const SETTLE_FRAMES := 90     # let the balls fall and land on the floor first
const TIMEOUT_FRAMES := 900   # safety net so a stuck state machine can't hang
const SETTLE_AFTER_COLLECT := 20  # queue_free is deferred; let the frees flush
const TARGET_COUNT := 6       # non-Dalek balls left in the pit (> DALEK_LASER_COUNT)

var _playground: Node2D
var _frame := 0
var _drop_triggered := false
var _collected := false
var _collect_frame := 0


func _ready() -> void:
	_playground = (load("res://claw/physics_playground.tscn") as PackedScene).instantiate()
	add_child(_playground)

	var balls_container: Node2D = _playground._balls_container
	var children := balls_container.get_children()

	# The first ball becomes the Dalek, parked dead-center under the claw.
	var dalek: PrizeBall = children[0]
	dalek.prize_id = "dalek"
	dalek.position = Vector2(0.0, GameData.PIT_HEIGHT - 40.0)

	# Keep TARGET_COUNT other balls, spread wide so they settle clear of the
	# claw's straight-down dive; free the rest so nothing else can be grabbed.
	var kept := 0
	for child in children:
		if child == dalek:
			continue
		if kept < TARGET_COUNT:
			var spread: float = GameData.PIT_WIDTH / 2.0 - 40.0
			var x: float = lerp(-spread, spread, float(kept) / float(TARGET_COUNT - 1))
			child.prize_id = "teddy"  # plain target; behaviour is Dalek-only
			child.position = Vector2(x, GameData.PIT_HEIGHT - 40.0)
			kept += 1
		else:
			child.queue_free()


func _physics_process(_delta: float) -> void:
	_frame += 1

	if _frame > TIMEOUT_FRAMES:
		_finish(false, "TIMEOUT: Dalek was never collected after %d frames" % TIMEOUT_FRAMES)
		return

	if not _drop_triggered:
		if _frame >= SETTLE_FRAMES:
			_drop_triggered = true
			_playground._claw.start_drop()
		return

	if not _collected:
		if GameState.collection.get("dalek", 0) > 0:
			_collected = true
			_collect_frame = _frame
		return

	# Give the laser queue_free()s a few frames to flush before counting.
	if _frame - _collect_frame >= SETTLE_AFTER_COLLECT:
		_check_result()


func _check_result() -> void:
	# The Dalek left the container the moment it was grabbed, so the container
	# started this run with TARGET_COUNT balls. The lasers then zapped
	# DALEK_LASER_COUNT of them, so this many should be left:
	var remaining: int = _playground._balls_container.get_child_count()
	var expected: int = TARGET_COUNT - GameData.DALEK_LASER_COUNT
	if remaining == expected:
		_finish(true, "PASS: Dalek grab zapped %d of %d target balls (%d left)" % [
			GameData.DALEK_LASER_COUNT, TARGET_COUNT, remaining])
	else:
		_finish(false, "FAIL: pit has %d balls, expected %d (%d targets, %d lasers)" % [
			remaining, expected, TARGET_COUNT, GameData.DALEK_LASER_COUNT])


func _finish(passed: bool, message: String) -> void:
	if passed:
		print(message)
	else:
		printerr(message)
	get_tree().quit(0 if passed else 1)
