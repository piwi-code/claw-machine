extends Node2D
## PHYSICS PLAYGROUND — slice 2 of the physics-based claw.
##
## Hold left/right to slide the claw, press DROP to dive, close, and rise.
## Balls are real RigidBody2D circles with gravity and collision, each rolled
## a prize_id (weighted by rarity, same table as the old dice-roll game) when
## it spawns — the dice-roll moved from "did you grab something" to "what's
## in the pit", per the physics claw notes in CLAUDE.md.
##
## A grab only pays out once the claw is fully retracted (ClawRig's
## `collected` signal). For now that's the whole "delivery" — no return-home
## animation or chute yet, the ball is just removed and replaced.
##
## The old idle game (main.gd / main.tscn) is untouched and still works; this
## is just a new scene that project.godot currently points to instead.


var _world: Node2D
var _claw: ClawRig
var _balls_container: Node2D
var _status_label: Label

# Coin counter + prize toast (top-left HUD column)
var _coins_label: Label
var _toast: PanelContainer
var _toast_label: Label
var _toast_ball_style: StyleBoxFlat
var _toast_tween: Tween

@onready var _ui_font: Font = load(GameData.UI_FONT)

# Left/right can be held via keyboard AND the on-screen buttons at once, so we
# track each source separately and combine them — releasing one shouldn't
# cancel a direction the other source is still holding.
var _key_left := false
var _key_right := false
var _button_left := false
var _button_right := false


func _ready() -> void:
	# Background goes in the tree first so everything else draws on top of it.
	_build_background()

	# World-local (0,0) is the top-center of the pit. Node2D's own (0,0) is the
	# viewport's top-left corner in screen space, so without this offset the
	# whole left half of the machine (every negative local x) would sit
	# off-screen. Center the world horizontally instead of assuming a camera.
	_world = Node2D.new()
	_world.position = Vector2(get_viewport_rect().size.x / 2.0, GameData.CEILING_Y)
	add_child(_world)

	_build_world()
	_build_claw()
	_build_balls()
	_build_ui()


func _build_world() -> void:
	var floor_body := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var floor_rect := RectangleShape2D.new()
	floor_rect.size = Vector2(GameData.PIT_WIDTH, 20)
	floor_shape.shape = floor_rect
	floor_body.add_child(floor_shape)
	floor_body.position = Vector2(0, GameData.PIT_HEIGHT)
	_world.add_child(floor_body)
	_add_pit_visual(floor_body, floor_rect.size)

	for side in [-1, 1]:
		var wall := StaticBody2D.new()
		var wall_shape := CollisionShape2D.new()
		var wall_rect := RectangleShape2D.new()
		wall_rect.size = Vector2(20, GameData.PIT_HEIGHT)
		wall_shape.shape = wall_rect
		wall.add_child(wall_shape)
		wall.position = Vector2(side * GameData.PIT_WIDTH / 2.0, GameData.PIT_HEIGHT / 2.0)
		_world.add_child(wall)
		_add_pit_visual(wall, wall_rect.size)

	_balls_container = Node2D.new()
	_world.add_child(_balls_container)


# Paints a pit collision body in the skin's cabinet purple so the machine's
# bounds are visible. A Panel (not ColorRect) so the corners can be rounded.
func _add_pit_visual(body: StaticBody2D, visual_size: Vector2) -> void:
	var panel := Panel.new()
	panel.size = visual_size
	panel.position = -visual_size / 2.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = GameData.SKIN["cabinet"]
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	body.add_child(panel)


func _build_background() -> void:
	var skin: Dictionary = GameData.SKIN

	# A CanvasLayer BELOW the default layer 0, not top_level controls: a
	# top_level canvas item paints on top of its parent's whole subtree, so a
	# full-screen top_level sky would cover the world (claw, balls, pit) even
	# though it comes first in tree order. A negative layer is always behind.
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -1
	add_child(bg_layer)

	var sky := TextureRect.new()
	var sky_gradient := Gradient.new()
	sky_gradient.offsets = PackedFloat32Array(skin["bg_offsets"])
	sky_gradient.colors = PackedColorArray(skin["bg_colors"])
	var sky_texture := GradientTexture2D.new()
	sky_texture.gradient = sky_gradient
	sky_texture.fill_from = Vector2(0, 0)
	sky_texture.fill_to = Vector2(0, 1)
	sky.texture = sky_texture
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_layer.add_child(sky)
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var floor_strip := TextureRect.new()
	var floor_gradient := Gradient.new()
	floor_gradient.offsets = PackedFloat32Array([0.0, 1.0])
	floor_gradient.colors = PackedColorArray([skin["floor_top"], skin["floor_bottom"]])
	var floor_texture := GradientTexture2D.new()
	floor_texture.gradient = floor_gradient
	floor_texture.fill_from = Vector2(0, 0)
	floor_texture.fill_to = Vector2(0, 1)
	floor_strip.texture = floor_texture
	floor_strip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	floor_strip.stretch_mode = TextureRect.STRETCH_SCALE
	floor_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_layer.add_child(floor_strip)
	floor_strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	floor_strip.offset_top = -skin["floor_height"]


func _build_claw() -> void:
	_claw = ClawRig.new()
	_claw.position = Vector2.ZERO
	_claw.move_bounds = Vector2(-GameData.PIT_WIDTH / 2.0 + 30.0, GameData.PIT_WIDTH / 2.0 - 30.0)
	_claw.grabbed.connect(func(_b): _status_label.text = "Got it! Bringing it home...")
	_claw.missed.connect(func(): _status_label.text = "Missed... try again!")
	_claw.collected.connect(_on_ball_collected)
	_world.add_child(_claw)


func _build_balls() -> void:
	for i in GameData.BALL_COUNT:
		_spawn_ball()


func _spawn_ball() -> void:
	var ball := PrizeBall.new()
	ball.prize_id = GameState.pick_weighted_prize()
	ball.position = Vector2(
		randf_range(-GameData.PIT_WIDTH / 2.0 + 40.0, GameData.PIT_WIDTH / 2.0 - 40.0),
		randf_range(GameData.PIT_HEIGHT - 150.0, GameData.PIT_HEIGHT - 30.0)
	)
	_balls_container.add_child(ball)


func _on_ball_collected(ball: Node) -> void:
	var prize_ball := ball as PrizeBall
	var coins_awarded := GameState.award_prize(prize_ball.prize_id)
	_show_prize_toast(prize_ball.prize_id, coins_awarded)
	_status_label.text = "Move the claw and press DROP!"

	ball.queue_free()
	_spawn_ball()


func _build_ui() -> void:
	var skin: Dictionary = GameData.SKIN

	_status_label = Label.new()
	_status_label.text = "Move the claw and press DROP!"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_override("font", _ui_font)
	_status_label.add_theme_font_size_override("font_size", 22)
	_status_label.add_theme_color_override("font_color", skin["status_text"])
	add_child(_status_label)
	_status_label.top_level = true  # see _make_top_level_ui() doc comment
	# The offsets variant, not set_anchors_preset: anchors alone leave the
	# label at its minimum text width, so "centered" text hugged the left
	# edge (and collided with the coin counter).
	_status_label.set_anchors_and_offsets_preset(
		Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 16)

	# Move buttons bottom-left and DROP bottom-right, both corner-anchored
	# (rather than one centered bar) so each sits under a thumb when the
	# tablet is held in both hands.
	const CORNER_MARGIN := 32

	var move_bar := HBoxContainer.new()
	move_bar.add_theme_constant_override("separation", 16)

	var left_btn := _make_hold_button("<")
	_style_round_button(left_btn, skin["arrow_bg"], skin["arrow_edge"], skin["arrow_text"], 40)
	left_btn.button_down.connect(_on_left_button_down)
	left_btn.button_up.connect(_on_left_button_up)
	move_bar.add_child(left_btn)

	var right_btn := _make_hold_button(">")
	_style_round_button(right_btn, skin["arrow_bg"], skin["arrow_edge"], skin["arrow_text"], 40)
	right_btn.button_down.connect(_on_right_button_down)
	right_btn.button_up.connect(_on_right_button_up)
	move_bar.add_child(right_btn)

	_make_top_level_ui(move_bar)
	move_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, CORNER_MARGIN)

	var drop_btn := _make_hold_button("DROP")
	drop_btn.custom_minimum_size = Vector2(160, 96)
	_style_round_button(drop_btn, skin["drop_bg"], skin["drop_edge"], skin["drop_text"], 30)
	# PRESET_MODE_MINSIZE would size this from Control.get_minimum_size(),
	# which for a plain Button is its own text/theme size and ignores
	# custom_minimum_size (that's only folded in by get_combined_minimum_size,
	# which the preset helper doesn't use) — so DROP would get anchored at
	# ~53x31 instead of the 160x96 it's actually drawn at. Force the real size
	# first and use KEEP_SIZE so the preset just anchors to it as-is.
	drop_btn.size = drop_btn.custom_minimum_size
	drop_btn.pressed.connect(func(): _claw.start_drop())
	_make_top_level_ui(drop_btn)
	drop_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE, CORNER_MARGIN)

	_build_coins_hud(CORNER_MARGIN)


# Coin counter pill top-left (above the movement buttons), with the prize
# toast underneath it: "you won X" that fades out after a few seconds. The
# toast is a stopgap — the collected prize will eventually be presented
# somewhere nicer (chute/collection); see ROADMAP.md.
func _build_coins_hud(margin: int) -> void:
	var skin: Dictionary = GameData.SKIN

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)

	var coin_pill := _make_pill()
	column.add_child(coin_pill)
	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 10)
	coin_pill.add_child(coin_row)

	var coin := Panel.new()
	coin.custom_minimum_size = Vector2(34, 34)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var coin_style := StyleBoxFlat.new()
	coin_style.bg_color = skin["coin_fill"]
	coin_style.border_color = skin["coin_edge"]
	coin_style.set_border_width_all(4)
	coin_style.set_corner_radius_all(999)  # circle
	coin.add_theme_stylebox_override("panel", coin_style)
	coin_row.add_child(coin)

	_coins_label = Label.new()
	_coins_label.text = str(GameState.coins)
	_coins_label.add_theme_font_override("font", _ui_font)
	_coins_label.add_theme_font_size_override("font_size", 24)
	_coins_label.add_theme_color_override("font_color", skin["pill_text"])
	coin_row.add_child(_coins_label)
	GameState.coins_changed.connect(func(new_total: int): _coins_label.text = str(new_total))

	_toast = _make_pill()
	_toast.visible = false
	column.add_child(_toast)
	var toast_row := HBoxContainer.new()
	toast_row.add_theme_constant_override("separation", 8)
	_toast.add_child(toast_row)

	var toast_ball := Panel.new()
	toast_ball.custom_minimum_size = Vector2(20, 20)
	toast_ball.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_toast_ball_style = StyleBoxFlat.new()
	_toast_ball_style.set_corner_radius_all(999)
	toast_ball.add_theme_stylebox_override("panel", _toast_ball_style)
	toast_row.add_child(toast_ball)

	_toast_label = Label.new()
	_toast_label.add_theme_font_override("font", _ui_font)
	_toast_label.add_theme_font_size_override("font_size", 18)
	_toast_label.add_theme_color_override("font_color", skin["pill_text"])
	toast_row.add_child(_toast_label)

	_make_top_level_ui(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, margin)


func _show_prize_toast(prize_id: String, coins_awarded: int) -> void:
	var prize: Dictionary = GameData.PRIZES[prize_id]
	_toast_ball_style.bg_color = prize["color"]
	_toast_label.text = "%s  +%d" % [prize["name"], coins_awarded]
	_toast.visible = true
	_toast.modulate.a = 1.0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(GameData.PRIZE_TOAST_SECONDS)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)
	_toast_tween.tween_callback(func(): _toast.visible = false)


# Cream rounded pill (coin counter, prize toast) in the arcade skin's style.
func _make_pill() -> PanelContainer:
	var skin: Dictionary = GameData.SKIN
	var pill := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = skin["pill_bg"]
	style.border_color = skin["pill_edge"]
	style.border_width_bottom = 6  # chunky arcade "3D" edge
	style.set_corner_radius_all(24)
	style.content_margin_left = 12
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	pill.add_theme_stylebox_override("panel", style)
	return pill


# Round/pill arcade button: flat pastel face, chunky darker bottom edge that
# compresses while pressed so it feels pushable.
func _style_round_button(btn: Button, bg: Color, edge: Color, text_color: Color, font_size: int) -> void:
	btn.add_theme_font_override("font", _ui_font)
	btn.add_theme_font_size_override("font_size", font_size)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(color_name, text_color)

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_corner_radius_all(999)  # clamped to circle/pill by Godot
	normal.border_width_bottom = 8
	normal.border_color = edge

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.05)
	pressed.border_width_bottom = 2

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", normal)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


# Adds `control` as a top-level child of this Node2D. `top_level = true` makes
# Godot anchor it against the real viewport instead of its parent's rect: a
# Control's anchor offsets are baked via get_parent_anchorable_rect(), which
# walks up to the nearest CanvasItem ancestor and calls its
# get_anchorable_rect() — a method only Control overrides meaningfully.
# Without top_level, that walk lands on this Node2D and hits CanvasItem's
# stub implementation (always an empty Rect2), collapsing every anchor
# preset — bottom-left, bottom-right, whatever — to the same (0, 0) point.
func _make_top_level_ui(control: Control) -> void:
	add_child(control)
	control.top_level = true


func _on_left_button_down() -> void:
	_button_left = true
	_update_move_direction()

func _on_left_button_up() -> void:
	_button_left = false
	_update_move_direction()

func _on_right_button_down() -> void:
	_button_right = true
	_update_move_direction()

func _on_right_button_up() -> void:
	_button_right = false
	_update_move_direction()


func _make_hold_button(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(96, 96)
	# Keyboard input is handled ourselves in _unhandled_input; keeping focus off
	# these buttons stops Godot's default Control navigation from stealing the
	# arrow keys and stops Space from double-triggering a focused button.
	btn.focus_mode = Control.FOCUS_NONE
	return btn


# --- Keyboard (desktop testing convenience alongside the on-screen buttons) --
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	match key_event.keycode:
		KEY_LEFT:
			_key_left = key_event.pressed
			_update_move_direction()
		KEY_RIGHT:
			_key_right = key_event.pressed
			_update_move_direction()
		KEY_SPACE:
			if key_event.pressed and not key_event.echo:
				_claw.start_drop()


func _update_move_direction() -> void:
	var left := _key_left or _button_left
	var right := _key_right or _button_right
	if left and not right:
		_claw.set_move_direction(-1)
	elif right and not left:
		_claw.set_move_direction(1)
	else:
		_claw.set_move_direction(0)
