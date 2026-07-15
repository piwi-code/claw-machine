class_name UISkin
## Shared "Arcade Pastel" styling helpers, so every scene (game, menu,
## dialogs) draws from the same skin. All colors/numbers come from
## GameData.SKIN — nothing visual is hard-coded here beyond structure.
## Pure helpers, no state: call the static functions from any scene.

static var _font: Font


static func font() -> Font:
	if _font == null:
		_font = load(GameData.UI_FONT)
	return _font


## Pastel sky gradient + warm floor strip, in a CanvasLayer BELOW layer 0 so
## it is always behind the scene's content (a top_level full-screen control
## would paint OVER its parent's whole subtree instead).
static func build_background(parent: Node) -> void:
	var skin: Dictionary = GameData.SKIN

	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -1
	parent.add_child(bg_layer)

	var sky := _gradient_rect(skin["bg_colors"], skin["bg_offsets"])
	bg_layer.add_child(sky)
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var floor_strip := _gradient_rect(
		[skin["floor_top"], skin["floor_bottom"]], [0.0, 1.0])
	bg_layer.add_child(floor_strip)
	floor_strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	floor_strip.offset_top = -skin["floor_height"]


static func _gradient_rect(colors: Array, offsets: Array) -> TextureRect:
	var rect := TextureRect.new()
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array(offsets)
	gradient.colors = PackedColorArray(colors)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)  # top-to-bottom
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## Round/pill arcade button: flat pastel face, chunky darker bottom edge that
## compresses while pressed so it feels pushable.
static func style_button(btn: Button, bg: Color, edge: Color, text_color: Color, font_size: int) -> void:
	btn.add_theme_font_override("font", font())
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


## The three button palettes from the design, so call sites don't repeat
## color plumbing: "primary" coral (DROP / main action), "secondary" mint
## (arrows / alternatives), "quiet" cream (low-stakes actions).
static func style_primary_button(btn: Button, font_size: int = 26) -> void:
	var skin: Dictionary = GameData.SKIN
	style_button(btn, skin["drop_bg"], skin["drop_edge"], skin["drop_text"], font_size)


static func style_secondary_button(btn: Button, font_size: int = 26) -> void:
	var skin: Dictionary = GameData.SKIN
	style_button(btn, skin["arrow_bg"], skin["arrow_edge"], skin["arrow_text"], font_size)


static func style_quiet_button(btn: Button, font_size: int = 26) -> void:
	var skin: Dictionary = GameData.SKIN
	style_button(btn, skin["pill_bg"], skin["pill_edge"], skin["pill_text"], font_size)


## The design's marquee badge (the "CLAW & CO." sign): pink pill, thick white
## border, white Fredoka text. Used for the menu title, the shop title, and
## the end-of-run sign.
static func make_marquee_title(text: String, font_size: int = 44) -> PanelContainer:
	var skin: Dictionary = GameData.SKIN
	var badge := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = skin["marquee_bg"]
	style.border_color = skin["marquee_border"]
	style.set_border_width_all(5)
	style.set_corner_radius_all(24)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 12
	style.content_margin_bottom = 14
	badge.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	style_label(label, font_size, skin["marquee_text"])
	badge.add_child(label)
	return badge


## Coin-counter pill: gold coin circle + amount. Returns {"pill": PanelContainer,
## "label": Label} so callers that need live updates can keep the label.
static func make_coin_pill(amount: int, font_size: int = 24) -> Dictionary:
	var skin: Dictionary = GameData.SKIN
	var pill := make_pill()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	pill.add_child(row)

	var coin := Panel.new()
	coin.custom_minimum_size = Vector2(34, 34)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var coin_style := StyleBoxFlat.new()
	coin_style.bg_color = skin["coin_fill"]
	coin_style.border_color = skin["coin_edge"]
	coin_style.set_border_width_all(4)
	coin_style.set_corner_radius_all(999)  # circle
	coin.add_theme_stylebox_override("panel", coin_style)
	row.add_child(coin)

	var label := Label.new()
	label.text = str(amount)
	style_label(label, font_size, skin["pill_text"])
	row.add_child(label)
	return {"pill": pill, "label": label}


## Cream rounded pill (coin counter, prize toast, dialog panels).
static func make_pill() -> PanelContainer:
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


static func style_label(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_override("font", font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
