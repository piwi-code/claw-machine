extends Node2D
## PHYSICS PLAYGROUND — slice 3 of the physics-based claw: timed RUNS.
##
## Hold left/right to slide the claw, press DROP to dive, close, and rise.
## Balls are real RigidBody2D circles with gravity and collision, each rolled
## a prize_id (weighted by rarity, same table as the old dice-roll game) when
## it spawns — the dice-roll moved from "did you grab something" to "what's
## in the pit", per the physics claw notes in CLAUDE.md.
##
## A grab only pays out once the claw is fully retracted (ClawRig's
## `collected` signal). Collected balls are NOT replaced: the pit starts with
## GameData.BALL_COUNT balls and only ever empties.
##
## This scene is one RUN in the shop <-> machine loop: a timer bar drains over
## GameData.RUN_SECONDS, and the run ends when time runs out (a dive already
## in motion is allowed to finish), the pit is cleared, or the player presses
## the END button on the timer bar. Then a "run over" sign shows for a few
## seconds and the game returns to the shop screen, which is also where this
## scene gets launched from.
##
## The old idle game (main.gd / main.tscn) is untouched and still works; this
## is just a new scene that project.godot currently points to instead.

const SHOP_SCENE := "res://shop/shop_screen.tscn"

# PLAYING: normal control. WAITING_FOR_CLAW: timer hit zero mid-dive — input
# is dead but the claw finishes its cycle (yanking a caught prize away at the
# buzzer would feel unfair). RUN_OVER: sign is up, shop scene is seconds away.
enum RunPhase { PLAYING, WAITING_FOR_CLAW, RUN_OVER }

var _phase := RunPhase.PLAYING
var _time_left: float = GameData.RUN_SECONDS
var _run_coins := 0  # winnings from THIS run only (totals live in GameState)

var _world: Node2D
var _claw: ClawRig
var _balls_container: Node2D
var _status_label: Label
var _timer_bar: ProgressBar

# Coin counter + prize toast (top-left HUD column)
var _coins_label: Label
var _toast: PanelContainer
var _toast_label: Label
var _toast_ball_style: StyleBoxFlat
var _toast_tween: Tween

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


func _process(delta: float) -> void:
	match _phase:
		RunPhase.PLAYING:
			_time_left = maxf(_time_left - delta, 0.0)
			_timer_bar.value = _time_left / GameData.RUN_SECONDS
			if _time_left <= 0.0:
				if _claw.state == ClawRig.State.IDLE:
					_end_run("Time's up!")
				else:
					_phase = RunPhase.WAITING_FOR_CLAW
					_claw.set_move_direction(0)
					_status_label.text = "Time's up!"
		RunPhase.WAITING_FOR_CLAW:
			# The in-flight dive has finished (any caught ball was collected
			# and paid out via _on_ball_collected on the way).
			if _claw.state == ClawRig.State.IDLE:
				_end_run("Time's up!")
		RunPhase.RUN_OVER:
			pass  # frozen; the return-to-shop timer is already running


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
	UISkin.build_background(self)


func _build_claw() -> void:
	_claw = ClawRig.new()
	_claw.position = Vector2.ZERO
	_claw.move_bounds = Vector2(-GameData.PIT_WIDTH / 2.0 + 30.0, GameData.PIT_WIDTH / 2.0 - 30.0)
	_claw.grabbed.connect(func(_b): _set_play_status("Got it! Bringing it home..."))
	_claw.missed.connect(func(): _set_play_status("Missed... try again!"))
	_claw.collected.connect(_on_ball_collected)
	_world.add_child(_claw)


func _build_balls() -> void:
	for i in GameData.BALL_COUNT:
		_spawn_ball()


func _spawn_ball() -> void:
	var ball := PrizeBall.new()
	ball.prize_id = GameState.pick_weighted_prize()
	# A tall spawn band: BALL_COUNT balls dropped into one thin strip would
	# start deeply overlapping and the physics engine would pop them apart.
	ball.position = Vector2(
		randf_range(-GameData.PIT_WIDTH / 2.0 + 40.0, GameData.PIT_WIDTH / 2.0 - 40.0),
		randf_range(GameData.PIT_HEIGHT - 260.0, GameData.PIT_HEIGHT - 30.0)
	)
	_balls_container.add_child(ball)


func _on_ball_collected(ball: Node) -> void:
	var prize_ball := ball as PrizeBall
	var coins_awarded := GameState.award_prize(prize_ball.prize_id)
	_run_coins += coins_awarded
	_show_prize_toast(prize_ball.prize_id, coins_awarded)
	_set_play_status("Move the claw and press DROP!")
	ball.queue_free()

	# Grabbing reparents a ball out of the container immediately, so its child
	# count is exactly the balls still in the pit. No respawn — emptying the
	# pit is one of the ways a run ends.
	if _balls_container.get_child_count() == 0:
		_end_run("Pit cleared!")


# Status chatter (got it / missed / prompt) only makes sense mid-run; once the
# timer is done the label belongs to "Time's up!" and the run-over sign.
func _set_play_status(text: String) -> void:
	if _phase == RunPhase.PLAYING:
		_status_label.text = text


func _end_run(reason: String) -> void:
	if _phase == RunPhase.RUN_OVER:
		return  # e.g. END pressed twice, or "Pit cleared!" racing "Time's up!"
	_phase = RunPhase.RUN_OVER
	_claw.set_move_direction(0)
	GameState.last_run_coins = _run_coins
	_status_label.text = ""
	_show_run_over_sign(reason)
	get_tree().create_timer(GameData.RUN_END_PAUSE_SECONDS).timeout.connect(
		func(): get_tree().change_scene_to_file(SHOP_SCENE))


# Big center-screen marquee shown while the run winds down.
func _show_run_over_sign(reason: String) -> void:
	var center := CenterContainer.new()
	_make_top_level_ui(center)
	# The offsets variant, not set_anchors_preset — anchors alone leave the
	# container at its minimum size, pinning the sign to the top-left corner.
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_child(UISkin.make_marquee_title(
		"%s\n+%d coins this run" % [reason, _run_coins], 34))


func _build_ui() -> void:
	var skin: Dictionary = GameData.SKIN

	# The timer bar spans the very top; everything else in the top strip
	# (status text, coin HUD) shifts down below it by this much.
	const TIMER_BAR_CLEARANCE := 56

	_build_timer_bar(16)

	_status_label = Label.new()
	_status_label.text = "Move the claw and press DROP!"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UISkin.style_label(_status_label, 22, skin["status_text"])
	add_child(_status_label)
	_status_label.top_level = true  # see _make_top_level_ui() doc comment
	# The offsets variant, not set_anchors_preset: anchors alone leave the
	# label at its minimum text width, so "centered" text hugged the left
	# edge (and collided with the coin counter).
	_status_label.set_anchors_and_offsets_preset(
		Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 16)
	_status_label.offset_top += TIMER_BAR_CLEARANCE
	_status_label.offset_bottom += TIMER_BAR_CLEARANCE

	# Move buttons bottom-left and DROP bottom-right, both corner-anchored
	# (rather than one centered bar) so each sits under a thumb when the
	# tablet is held in both hands.
	const CORNER_MARGIN := 32

	var move_bar := HBoxContainer.new()
	move_bar.add_theme_constant_override("separation", 16)

	var left_btn := _make_hold_button("<")
	UISkin.style_secondary_button(left_btn, 40)
	left_btn.button_down.connect(_on_left_button_down)
	left_btn.button_up.connect(_on_left_button_up)
	move_bar.add_child(left_btn)

	var right_btn := _make_hold_button(">")
	UISkin.style_secondary_button(right_btn, 40)
	right_btn.button_down.connect(_on_right_button_down)
	right_btn.button_up.connect(_on_right_button_up)
	move_bar.add_child(right_btn)

	_make_top_level_ui(move_bar)
	move_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, CORNER_MARGIN)

	var drop_btn := _make_hold_button("DROP")
	drop_btn.custom_minimum_size = Vector2(160, 96)
	UISkin.style_primary_button(drop_btn, 30)
	# PRESET_MODE_MINSIZE would size this from Control.get_minimum_size(),
	# which for a plain Button is its own text/theme size and ignores
	# custom_minimum_size (that's only folded in by get_combined_minimum_size,
	# which the preset helper doesn't use) — so DROP would get anchored at
	# ~53x31 instead of the 160x96 it's actually drawn at. Force the real size
	# first and use KEEP_SIZE so the preset just anchors to it as-is.
	drop_btn.size = drop_btn.custom_minimum_size
	drop_btn.pressed.connect(_on_drop_pressed)
	_make_top_level_ui(drop_btn)
	drop_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE, CORNER_MARGIN)

	_build_coins_hud(CORNER_MARGIN, TIMER_BAR_CLEARANCE)


# The draining run timer along the top, with the END button riding its right
# end — one glance says "this is the time left in your go, this is the way
# out". END gives up the rest of the run immediately (winnings are kept —
# they were banked in GameState the moment each ball was collected).
func _build_timer_bar(margin: int) -> void:
	var skin: Dictionary = GameData.SKIN

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	_timer_bar = ProgressBar.new()
	_timer_bar.max_value = 1.0
	_timer_bar.value = 1.0
	_timer_bar.show_percentage = false
	_timer_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_timer_bar.custom_minimum_size = Vector2(0, 44)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = skin["pill_bg"]
	bg_style.border_color = skin["pill_edge"]
	bg_style.set_border_width_all(3)
	bg_style.set_corner_radius_all(999)  # pill
	_timer_bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = skin["drop_bg"]
	fill_style.set_corner_radius_all(999)
	_timer_bar.add_theme_stylebox_override("fill", fill_style)

	row.add_child(_timer_bar)

	var end_btn := Button.new()
	end_btn.text = "END"
	end_btn.focus_mode = Control.FOCUS_NONE
	end_btn.custom_minimum_size = Vector2(96, 44)
	UISkin.style_quiet_button(end_btn, 20)
	end_btn.pressed.connect(_on_end_button_pressed)
	row.add_child(end_btn)

	_make_top_level_ui(row)
	row.set_anchors_and_offsets_preset(
		Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, margin)


# Coin counter pill top-left (above the movement buttons), with the prize
# toast underneath it: "you won X" that fades out after a few seconds. The
# toast is a stopgap — the collected prize will eventually be presented
# somewhere nicer (chute/collection); see ROADMAP.md.
func _build_coins_hud(margin: int, top_clearance: int) -> void:
	var skin: Dictionary = GameData.SKIN

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)

	var coin := UISkin.make_coin_pill(GameState.coins)
	column.add_child(coin["pill"])
	_coins_label = coin["label"]
	GameState.coins_changed.connect(func(new_total: int): _coins_label.text = str(new_total))

	_toast = UISkin.make_pill()
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
	UISkin.style_label(_toast_label, 18, skin["pill_text"])
	toast_row.add_child(_toast_label)

	_make_top_level_ui(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, margin)
	column.offset_top += top_clearance
	column.offset_bottom += top_clearance


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


func _on_drop_pressed() -> void:
	if _phase == RunPhase.PLAYING:
		_claw.start_drop()


func _on_end_button_pressed() -> void:
	# Quick exit: ends the run right now, even mid-dive (a ball still in the
	# claw's grip isn't collected — leaving early means leaving it behind).
	if _phase != RunPhase.RUN_OVER:
		_end_run("Run ended!")


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
				_on_drop_pressed()


func _update_move_direction() -> void:
	if _phase != RunPhase.PLAYING:
		_claw.set_move_direction(0)
		return
	var left := _key_left or _button_left
	var right := _key_right or _button_right
	if left and not right:
		_claw.set_move_direction(-1)
	elif right and not left:
		_claw.set_move_direction(1)
	else:
		_claw.set_move_direction(0)
