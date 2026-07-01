extends Node2D
## HEADLESS REGRESSION TEST — no editor, no human, no UI.
##
## Builds the same pit floor + a single ball as the real playground (same
## GameData constants, so it can't silently drift out of sync), lets the ball
## settle under real gravity, then drives the claw exactly like a player would
## (start_drop()) and asserts it actually grabs something.
##
## This exists because a tuning mistake (CLAW_MAX_DROP_DEPTH too shallow to
## reach a resting ball) shipped once already and only showed up in manual
## playtesting. Run it with tests/run_headless.sh, or directly:
##   godot --headless --path . res://tests/grab_regression_test.tscn
## Exits 0 on pass, 1 on fail/timeout — safe to wire into CI later.

const SETTLE_FRAMES := 90     # let the ball fall and land on the floor first
const TIMEOUT_FRAMES := 600   # safety net so a stuck state machine can't hang

var _claw: ClawRig
var _grabbed := false
var _drop_triggered := false
var _frame := 0


func _ready() -> void:
	var floor_body := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var floor_rect := RectangleShape2D.new()
	floor_rect.size = Vector2(GameData.PIT_WIDTH, 20)
	floor_shape.shape = floor_rect
	floor_body.add_child(floor_shape)
	floor_body.position = Vector2(0, GameData.PIT_HEIGHT)
	add_child(floor_body)

	var ball := PrizeBall.new()
	ball.position = Vector2(0, GameData.PIT_HEIGHT - 150.0)
	add_child(ball)

	_claw = ClawRig.new()
	_claw.balls_container = self
	_claw.grabbed.connect(func(_b): _grabbed = true)
	add_child(_claw)


func _physics_process(_delta: float) -> void:
	_frame += 1

	if _frame > TIMEOUT_FRAMES:
		_finish(false, "TIMEOUT: claw never returned to IDLE after %d frames" % TIMEOUT_FRAMES)
		return

	if not _drop_triggered:
		if _frame >= SETTLE_FRAMES:
			_drop_triggered = true
			_claw.start_drop()
		return

	if _claw.state == ClawRig.State.IDLE:
		if _grabbed:
			_finish(true, "PASS: claw grabbed the resting ball")
		else:
			_finish(false, "FAIL: claw dove and rose without grabbing the ball")


func _finish(passed: bool, message: String) -> void:
	if passed:
		print(message)
	else:
		printerr(message)
	get_tree().quit(0 if passed else 1)
