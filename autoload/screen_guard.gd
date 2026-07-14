extends Node
## Autoload "ScreenGuard". Keeps the game presentable on every screen shape:
##  - desktop: enforces a minimum window size so the layout can't be crushed
##  - everywhere: shows a friendly "turn your device sideways" overlay while
##    the window is portrait-shaped (a phone held upright, or a desktop
##    window dragged taller than it is wide)
##
## The Android app never needs the overlay — it locks to landscape natively
## via project.godot's display/window/handheld/orientation. On the web the
## browser owns orientation (the lock API only works in fullscreen and iOS
## ignores it), so a prompt is the honest option. The loading screen has its
## own copy of this hint in web/custom_shell.html, for before the engine runs.

const MIN_WINDOW_SIZE := Vector2i(960, 540)

const BACKDROP_COLOR := Color("28222e")
const PHONE_COLOR := Color("3d3547")
const ACCENT_COLOR := Color("f2d5a0")

var _overlay: CanvasLayer


func _ready() -> void:
	# Only desktop windows are ours to constrain — the browser and Android
	# own their windows.
	if not OS.has_feature("web") and not OS.has_feature("mobile"):
		get_window().min_size = MIN_WINDOW_SIZE

	_overlay = _build_overlay()
	add_child(_overlay)
	get_window().size_changed.connect(_update_overlay)
	_update_overlay()


func _update_overlay() -> void:
	var size := get_window().size
	_overlay.visible = size.x < size.y


func _build_overlay() -> CanvasLayer:
	# High layer so it covers any scene; the backdrop also swallows input so
	# a portrait-squished game can't be mis-tapped behind it.
	var layer := CanvasLayer.new()
	layer.layer = 100

	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 28)
	center.add_child(column)

	# A little landscape-phone pictogram, drawn with a StyleBox instead of an
	# emoji so it renders identically on every platform/font.
	var phone := Panel.new()
	phone.custom_minimum_size = Vector2(150, 78)
	phone.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = PHONE_COLOR
	style.border_color = ACCENT_COLOR
	style.set_border_width_all(4)
	style.set_corner_radius_all(16)
	phone.add_theme_stylebox_override("panel", style)
	column.add_child(phone)

	var title := Label.new()
	title.text = "Turn your device sideways!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", ACCENT_COLOR)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "This game is wide, not tall :)"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", ACCENT_COLOR.darkened(0.25))
	column.add_child(subtitle)

	return layer
