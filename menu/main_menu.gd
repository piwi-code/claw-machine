extends Control
## MAIN MENU — the game's entry point.
##
## Shows "Continue" only when a save already exists; "New Game" wipes
## GameState back to defaults (with a confirmation, since that's destructive)
## and starts the same scene fresh. Built entirely in code, per the
## code-first convention in CLAUDE.md.

const PLAYGROUND_SCENE := "res://claw/physics_playground.tscn"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)

	var title := Label.new()
	title.text = "Claw Machine"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	column.add_child(title)

	var button_column := VBoxContainer.new()
	button_column.add_theme_constant_override("separation", 12)
	column.add_child(button_column)

	if GameState.has_save():
		var continue_btn := _make_menu_button("Continue")
		continue_btn.pressed.connect(_on_continue_pressed)
		button_column.add_child(continue_btn)

		var new_game_btn := _make_menu_button("New Game")
		new_game_btn.pressed.connect(_on_new_game_pressed)
		button_column.add_child(new_game_btn)
	else:
		var start_btn := _make_menu_button("New Game")
		start_btn.pressed.connect(_start_new_game)
		button_column.add_child(start_btn)


func _make_menu_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(240, 64)
	return btn


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file(PLAYGROUND_SCENE)


# New Game is destructive when a save exists, so confirm before wiping it.
func _on_new_game_pressed() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "Start a new game? This erases your current coins and collection."
	dialog.confirmed.connect(_start_new_game)
	add_child(dialog)
	dialog.popup_centered()


func _start_new_game() -> void:
	GameState.reset_game()
	get_tree().change_scene_to_file(PLAYGROUND_SCENE)
