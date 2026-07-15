extends Control
## MAIN MENU — the game's entry point.
##
## Shows "Continue" only when a save already exists; "New Game" wipes
## GameState back to defaults (with a confirmation, since that's destructive).
## Both lead to the shop screen — the hub of the shop <-> claw-run loop —
## not straight into the machine. Built entirely in code, per the code-first
## convention in CLAUDE.md.

const SHOP_SCENE := "res://shop/shop_screen.tscn"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UISkin.build_background(self)
	_build_ui()


func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 28)
	center.add_child(column)

	column.add_child(UISkin.make_marquee_title("Claw Machine"))

	var button_column := VBoxContainer.new()
	button_column.add_theme_constant_override("separation", 14)
	column.add_child(button_column)

	# The most likely tap is coral (primary), alternatives are mint, and the
	# low-stakes Exit is quiet cream — same language as the game's buttons.
	if GameState.has_save():
		var continue_btn := _make_menu_button("Continue")
		UISkin.style_primary_button(continue_btn)
		continue_btn.pressed.connect(_on_continue_pressed)
		button_column.add_child(continue_btn)

		var new_game_btn := _make_menu_button("New Game")
		UISkin.style_secondary_button(new_game_btn)
		new_game_btn.pressed.connect(_on_new_game_pressed)
		button_column.add_child(new_game_btn)
	else:
		var start_btn := _make_menu_button("New Game")
		UISkin.style_primary_button(start_btn)
		start_btn.pressed.connect(_start_new_game)
		button_column.add_child(start_btn)

	# Quitting a web build means closing the browser tab, not the game — and
	# browsers block scripted tab-close anyway — so there's nothing useful for
	# this button to do there. Desktop/Android windows can actually exit.
	if not OS.has_feature("web"):
		var exit_btn := _make_menu_button("Exit")
		UISkin.style_quiet_button(exit_btn)
		exit_btn.pressed.connect(_on_exit_pressed)
		button_column.add_child(exit_btn)


func _make_menu_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(240, 64)
	btn.focus_mode = Control.FOCUS_NONE
	return btn


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file(SHOP_SCENE)


# New Game is destructive when a save exists, so confirm before wiping it.
func _on_new_game_pressed() -> void:
	var dialog := SkinConfirmDialog.new()
	dialog.message = "Start a new game? This erases your current coins and collection."
	dialog.confirm_text = "Start over!"
	dialog.confirmed.connect(_start_new_game)
	add_child(dialog)


func _start_new_game() -> void:
	GameState.reset_game()
	get_tree().change_scene_to_file(SHOP_SCENE)


func _on_exit_pressed() -> void:
	get_tree().quit()
