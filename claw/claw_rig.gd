extends Node2D
class_name ClawRig
## Physics playground claw: a carriage that slides left/right on a track, an
## arm that dives straight down, and a pincer that grabs whatever's underneath.
##
## Movement is locked while diving/rising, like a real claw machine. Grabbing
## is "kinematic carry": we freeze the ball and reparent it under the claw head,
## so it rides along for free via the normal node transform — no joints needed.
## A grab isn't final until the claw is fully retracted — that's when
## `collected` fires and the ball stops being this rig's concern.
##
## Deliberately dumb about WHAT it grabs or what collecting means — that's for
## the listener to decide (see the physics claw notes in CLAUDE.md).

signal grabbed(ball: RigidBody2D)
signal missed()
signal collected(ball: RigidBody2D)

enum State { IDLE, DIVING, CLOSING, RISING }

var move_bounds: Vector2 = Vector2(-300.0, 300.0)  # min/max local x for the carriage

var state: State = State.IDLE
var _move_direction: int = 0
var _depth: float = 0.0
var _held_ball: RigidBody2D = null

var _head: Node2D
var _grab_area: Area2D
var _arm_line: Line2D


func _ready() -> void:
	_arm_line = Line2D.new()
	_arm_line.width = 4.0
	_arm_line.default_color = GameData.SKIN["cabinet"]
	_arm_line.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	add_child(_arm_line)

	_head = Node2D.new()
	add_child(_head)

	_grab_area = Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = GameData.CLAW_GRAB_RADIUS
	shape.shape = circle
	_grab_area.add_child(shape)
	_head.add_child(_grab_area)

	_head.add_child(_make_pincer(-1))
	_head.add_child(_make_pincer(1))

	_update_visuals()


func _make_pincer(side: int) -> Polygon2D:
	var poly := Polygon2D.new()
	var r := GameData.CLAW_GRAB_RADIUS
	poly.polygon = PackedVector2Array([
		Vector2(0, -r * 0.3),
		Vector2(side * r * 0.9, r * 0.9),
		Vector2(side * r * 0.4, r * 1.1),
	])
	poly.color = GameData.SKIN["cabinet"]
	return poly


# --- Input (called from the on-screen buttons) ------------------------------
func set_move_direction(direction: int) -> void:
	_move_direction = clampi(direction, -1, 1)


func start_drop() -> void:
	if state == State.IDLE:
		state = State.DIVING


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			if _move_direction != 0:
				var new_x := position.x + _move_direction * GameData.CLAW_MOVE_SPEED * delta
				position.x = clampf(new_x, move_bounds.x, move_bounds.y)
		State.DIVING:
			_depth = minf(_depth + GameData.CLAW_DROP_SPEED * delta, GameData.CLAW_MAX_DROP_DEPTH)
			if _depth >= GameData.CLAW_MAX_DROP_DEPTH:
				state = State.CLOSING
				_attempt_grab()
		State.CLOSING:
			state = State.RISING
		State.RISING:
			_depth = maxf(_depth - GameData.CLAW_RISE_SPEED * delta, 0.0)
			if _depth <= 0.0:
				state = State.IDLE
				if _held_ball != null:
					var ball := _held_ball
					_held_ball = null
					collected.emit(ball)
	_update_visuals()


func _update_visuals() -> void:
	_head.position = Vector2(0, _depth)
	_arm_line.points = PackedVector2Array([Vector2.ZERO, _head.position])


func _attempt_grab() -> void:
	var best: RigidBody2D = null
	var best_dist := INF
	for body in _grab_area.get_overlapping_bodies():
		if body is RigidBody2D and body.is_in_group("balls"):
			var dist: float = body.global_position.distance_to(_grab_area.global_position)
			if dist < best_dist:
				best = body
				best_dist = dist

	if best == null:
		missed.emit()
		return

	_held_ball = best
	best.freeze = true
	best.global_position = _grab_area.global_position
	best.reparent(_head, true)
	grabbed.emit(best)
