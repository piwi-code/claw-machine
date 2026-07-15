extends Control
## SHOP / REVIEW SCREEN — the hub of the game loop.
##
## The loop is: main menu -> HERE -> claw run -> back HERE -> ... Shows the
## player's total coins and collection (tallied across every run, read straight
## from GameState — nothing is recomputed or stored here), plus a "last run"
## line right after a run. From here you start another run or head back to the
## main menu.
##
## Power-up purchases (more run time, more balls, better prize odds) will live
## on this screen later — see ROADMAP.md. For now it's review + "go again".

const PLAYGROUND_SCENE := "res://claw/physics_playground.tscn"
const MENU_SCENE := "res://menu/main_menu.tscn"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UISkin.build_background(self)
	_build_ui()


func _build_ui() -> void:
	var skin: Dictionary = GameData.SKIN

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(column)

	column.add_child(UISkin.make_marquee_title("Prize Shop", 36))

	# Total coins, centered. The pill hugs its content, so wrap it in a
	# CenterContainer instead of letting the VBox stretch it full-width.
	var coin_center := CenterContainer.new()
	column.add_child(coin_center)
	coin_center.add_child(UISkin.make_coin_pill(GameState.coins, 26)["pill"])

	if GameState.last_run_coins >= 0:
		var last_run := Label.new()
		last_run.text = "Last run: +%d coins" % GameState.last_run_coins
		last_run.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UISkin.style_label(last_run, 20, skin["status_text"])
		column.add_child(last_run)

	column.add_child(_make_collection_panel())

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 14)
	column.add_child(button_row)

	var play_btn := _make_button("PLAY", Vector2(220, 64))
	UISkin.style_primary_button(play_btn, 28)
	play_btn.pressed.connect(_on_play_pressed)
	button_row.add_child(play_btn)

	var menu_btn := _make_button("Menu", Vector2(140, 64))
	UISkin.style_quiet_button(menu_btn, 22)
	menu_btn.pressed.connect(_on_menu_pressed)
	button_row.add_child(menu_btn)


# One row per prize type: color dot, name, and how many have been won in
# total. All prizes are listed (even at x0) so the full collectible set is
# visible — that's the "review" half of this screen.
func _make_collection_panel() -> PanelContainer:
	var skin: Dictionary = GameData.SKIN
	var pill := UISkin.make_pill()

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	rows.custom_minimum_size = Vector2(320, 0)
	pill.add_child(rows)

	for prize_id in GameData.PRIZES:
		var prize: Dictionary = GameData.PRIZES[prize_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		rows.add_child(row)

		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(20, 20)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var dot_style := StyleBoxFlat.new()
		dot_style.bg_color = prize["color"]
		dot_style.set_corner_radius_all(999)  # circle
		dot.add_theme_stylebox_override("panel", dot_style)
		row.add_child(dot)

		var name_label := Label.new()
		name_label.text = prize["name"]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UISkin.style_label(name_label, 20, skin["pill_text"])
		row.add_child(name_label)

		var count_label := Label.new()
		count_label.text = "× %d" % GameState.collection.get(prize_id, 0)
		UISkin.style_label(count_label, 20, skin["pill_text"])
		row.add_child(count_label)

	return pill


func _make_button(text: String, min_size: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.focus_mode = Control.FOCUS_NONE
	return btn


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(PLAYGROUND_SCENE)


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
