extends Node2D
## PHYSICS PLAYGROUND — slice 1 of the physics-based claw.
##
## Pure movement/grab feel: hold left/right to slide the claw, press DROP to
## dive, close, and rise. Balls are real RigidBody2D circles with gravity and
## collision. There is NO scoring here on purpose — no coins, no prizes, no
## GameState calls. That wiring is a deliberately separate later slice (see the
## physics claw notes in CLAUDE.md) once this feels good to play with.
##
## The old idle game (main.gd / main.tscn) is untouched and still works; this
## is just a new scene that project.godot currently points to instead.


const PIT_WIDTH := 600.0
const PIT_HEIGHT := 420.0
const CEILING_Y := 40.0

var _world: Node2D
var _claw: ClawRig
var _balls_container: Node2D
var _status_label: Label


func _ready() -> void:
	# World-local (0,0) is the top-center of the pit. Node2D's own (0,0) is the
	# viewport's top-left corner in screen space, so without this offset the
	# whole left half of the machine (every negative local x) would sit
	# off-screen. Center the world horizontally instead of assuming a camera.
	_world = Node2D.new()
	_world.position = Vector2(get_viewport_rect().size.x / 2.0, CEILING_Y)
	add_child(_world)

	_build_world()
	_build_claw()
	_build_balls()
	_build_ui()


func _build_world() -> void:
	var floor_body := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var floor_rect := RectangleShape2D.new()
	floor_rect.size = Vector2(PIT_WIDTH, 20)
	floor_shape.shape = floor_rect
	floor_body.add_child(floor_shape)
	floor_body.position = Vector2(0, PIT_HEIGHT)
	_world.add_child(floor_body)

	for side in [-1, 1]:
		var wall := StaticBody2D.new()
		var wall_shape := CollisionShape2D.new()
		var wall_rect := RectangleShape2D.new()
		wall_rect.size = Vector2(20, PIT_HEIGHT)
		wall_shape.shape = wall_rect
		wall.add_child(wall_shape)
		wall.position = Vector2(side * PIT_WIDTH / 2.0, PIT_HEIGHT / 2.0)
		_world.add_child(wall)

	_balls_container = Node2D.new()
	_world.add_child(_balls_container)


func _build_claw() -> void:
	_claw = ClawRig.new()
	_claw.position = Vector2.ZERO
	_claw.move_bounds = Vector2(-PIT_WIDTH / 2.0 + 30.0, PIT_WIDTH / 2.0 - 30.0)
	_claw.balls_container = _balls_container
	_claw.grabbed.connect(func(_b): _status_label.text = "Grabbed one!")
	_claw.missed.connect(func(): _status_label.text = "Missed... try again!")
	_claw.released.connect(func(_b): _status_label.text = "Dropped it.")
	_world.add_child(_claw)


func _build_balls() -> void:
	for i in GameData.BALL_COUNT:
		var ball := PrizeBall.new()
		ball.color = Color.from_hsv(randf(), 0.55, 0.9)
		ball.position = Vector2(
			randf_range(-PIT_WIDTH / 2.0 + 40.0, PIT_WIDTH / 2.0 - 40.0),
			randf_range(PIT_HEIGHT - 150.0, PIT_HEIGHT - 30.0)
		)
		_balls_container.add_child(ball)


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_status_label = Label.new()
	_status_label.text = "Move the claw and press DROP!"
	root.add_child(_status_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var bottom_bar := HBoxContainer.new()
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_bar.add_theme_constant_override("separation", 24)
	root.add_child(bottom_bar)

	var left_btn := _make_hold_button("<")
	left_btn.button_down.connect(func(): _claw.set_move_direction(-1))
	left_btn.button_up.connect(func(): _claw.set_move_direction(0))
	bottom_bar.add_child(left_btn)

	var drop_btn := _make_hold_button("DROP")
	drop_btn.custom_minimum_size = Vector2(160, 96)
	drop_btn.pressed.connect(func(): _claw.start_drop())
	bottom_bar.add_child(drop_btn)

	var right_btn := _make_hold_button(">")
	right_btn.button_down.connect(func(): _claw.set_move_direction(1))
	right_btn.button_up.connect(func(): _claw.set_move_direction(0))
	bottom_bar.add_child(right_btn)


func _make_hold_button(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(96, 96)
	return btn
