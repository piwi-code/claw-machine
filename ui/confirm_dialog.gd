class_name SkinConfirmDialog
extends Control
## A confirm dialog in the arcade skin: dimmed backdrop, cream pill panel,
## coral confirm / mint cancel. Replaces Godot's native ConfirmationDialog,
## which draws OS-style window chrome that can't match the game's look.
##
## Usage (code-first, like everything else):
##   var dialog := SkinConfirmDialog.new()
##   dialog.message = "Really do the thing?"
##   dialog.confirmed.connect(_do_the_thing)
##   add_child(dialog)
##
## Cancel (or tapping the backdrop) just closes it; both paths free the node.

signal confirmed

var message := ""
var confirm_text := "Yes!"
var cancel_text := "Cancel"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.color = Color(GameData.SKIN["status_text"], 0.45)  # dim purple
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Swallow taps outside the panel — and treat them as "cancel".
	backdrop.gui_input.connect(_on_backdrop_input)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := UISkin.make_pill()
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	panel.add_child(column)

	var text := Label.new()
	text.text = message
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(420, 0)
	UISkin.style_label(text, 22, GameData.SKIN["status_text"])
	column.add_child(text)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(buttons)

	var cancel_btn := Button.new()
	cancel_btn.text = cancel_text
	cancel_btn.custom_minimum_size = Vector2(160, 56)
	UISkin.style_secondary_button(cancel_btn, 22)
	cancel_btn.pressed.connect(queue_free)
	buttons.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = confirm_text
	confirm_btn.custom_minimum_size = Vector2(160, 56)
	UISkin.style_primary_button(confirm_btn, 22)
	confirm_btn.pressed.connect(_on_confirmed)
	buttons.add_child(confirm_btn)


func _on_confirmed() -> void:
	confirmed.emit()
	queue_free()


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		queue_free()
