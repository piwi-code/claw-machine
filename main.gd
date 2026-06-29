extends Control
## TEMPORARY TEST HARNESS.
##
## This builds a plain, ugly little UI entirely in code, for one reason: so the
## game is fully playable the moment you press Play — no scene-building required.
## You can drop the claw, win prizes, watch coins go up, and buy upgrades today.
##
## NONE of the game's logic lives here. When you're ready for the cozy look,
## build a proper scene with real art and delete this file — the game keeps
## working, because GameState / ClawMachine / GameData don't depend on it.


var _claw: ClawMachine
var _coins_label: Label
var _result_label: Label
var _collection_label: Label
var _upgrade_buttons: Dictionary = {}


func _ready() -> void:
	_claw = ClawMachine.new()
	add_child(_claw)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	_coins_label = Label.new()
	root.add_child(_coins_label)

	var drop_btn := Button.new()
	drop_btn.text = "Drop the Claw!"
	drop_btn.custom_minimum_size = Vector2(0, 72)
	drop_btn.pressed.connect(_on_drop_pressed)
	root.add_child(drop_btn)

	_result_label = Label.new()
	_result_label.text = "Tap to play!"
	root.add_child(_result_label)

	root.add_child(HSeparator.new())

	# One shop button per upgrade — built straight from the data file, so new
	# upgrades you add in game_data.gd show up here with no extra UI work.
	for id in GameData.UPGRADES:
		var btn := Button.new()
		btn.pressed.connect(_on_buy_upgrade.bind(id))
		root.add_child(btn)
		_upgrade_buttons[id] = btn

	root.add_child(HSeparator.new())
	_collection_label = Label.new()
	root.add_child(_collection_label)

	# Listen for state changes instead of checking every frame.
	GameState.coins_changed.connect(func(_c): _refresh())
	GameState.upgrade_purchased.connect(func(_id, _lvl): _refresh())
	GameState.prize_won.connect(_on_prize_won)
	GameState.grab_failed.connect(_on_grab_failed)

	_refresh()


func _on_drop_pressed() -> void:
	# The grab result is also returned (success / prize_id / coins_awarded) if
	# you ever want to drive animation from it directly. Here, the signals below
	# update the UI for us.
	_claw.attempt_grab()

func _on_prize_won(_prize_id: String, prize_data: Dictionary) -> void:
	_result_label.text = "You grabbed a %s!" % prize_data["name"]

func _on_grab_failed() -> void:
	_result_label.text = "So close! The claw slipped..."

func _on_buy_upgrade(id: String) -> void:
	GameState.buy_upgrade(id)  # quietly does nothing if you can't afford it


func _refresh() -> void:
	_coins_label.text = "Coins: %d" % GameState.coins

	for id in _upgrade_buttons:
		var data: Dictionary = GameData.UPGRADES[id]
		var btn: Button = _upgrade_buttons[id]
		if GameState.is_upgrade_maxed(id):
			btn.text = "%s  (MAX)" % data["name"]
			btn.disabled = true
		else:
			btn.text = "%s  Lv.%d  —  %d coins" % [
				data["name"], GameState.get_upgrade_level(id), GameState.get_upgrade_cost(id)
			]
			btn.disabled = not GameState.can_afford_upgrade(id)

	_refresh_collection()


func _refresh_collection() -> void:
	if GameState.collection.is_empty():
		_collection_label.text = "Collection: (empty)"
		return
	var parts: Array[String] = []
	for id in GameState.collection:
		parts.append("%s x%d" % [GameData.PRIZES[id]["name"], GameState.collection[id]])
	_collection_label.text = "Collection: " + ", ".join(parts)
