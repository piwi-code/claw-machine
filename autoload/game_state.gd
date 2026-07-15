extends Node
## GAME STATE — the single source of truth for everything the player has earned.
##
## This is registered as an Autoload named "GameState", so every other script
## can read it from anywhere just by typing `GameState.coins`, etc.
## (Setup: Project > Project Settings > Globals/Autoload — see the README.)
##
## It also owns saving and loading. Logic talks to GameState; GameState shouts
## out SIGNALS when something changes; the UI listens. That keeps the game logic
## and the on-screen stuff cleanly separated — and easy for an AI to reason about.


# --- Signals: the UI connects to these instead of constantly polling --------
signal coins_changed(new_total: int)
signal prize_won(prize_id: String, prize_data: Dictionary)
signal grab_failed()
signal upgrade_purchased(upgrade_id: String, new_level: int)


const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

# --- The actual saved state -------------------------------------------------
var coins: int = GameData.STARTING_COINS
var upgrade_levels: Dictionary = {}   # { "grip_strength": 3, ... }
var collection: Dictionary = {}       # { "teddy": 7, "bunny": 2, ... } — how many won
var total_grabs: int = 0
var last_played_unix: int = 0         # used later for offline/away progress

# --- Transient run summary (deliberately NOT saved) ---------------------------
# The physics claw sets this at the end of every run so the shop screen can
# show "last run: +N coins". -1 means no run has finished since launch.
var last_run_coins: int = -1


func _ready() -> void:
	load_game()


# --- Earning ----------------------------------------------------------------
func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)

func register_prize(prize_id: String) -> void:
	collection[prize_id] = collection.get(prize_id, 0) + 1
	prize_won.emit(prize_id, GameData.PRIZES[prize_id])


# --- Prize picking / awarding -------------------------------------------------
# Shared by every claw mechanic (dice-roll and physics), so "which prize" and
# "what happens when you win one" stay identical no matter how the grab itself
# gets decided.
func pick_weighted_prize() -> String:
	var total_weight := 0
	for id in GameData.PRIZES:
		total_weight += GameData.PRIZES[id]["weight"]

	var roll := randi() % total_weight
	var cumulative := 0
	for id in GameData.PRIZES:
		cumulative += GameData.PRIZES[id]["weight"]
		if roll < cumulative:
			return id
	return GameData.PRIZES.keys()[0]  # fallback — shouldn't be reached

func award_prize(prize_id: String) -> int:
	var coins_awarded := int(round(GameData.PRIZES[prize_id]["value"] * get_coin_multiplier()))
	register_prize(prize_id)
	add_coins(coins_awarded)
	save_game()
	return coins_awarded


# --- Derived values (computed in ONE place, so the claw and the UI agree) ---
# When you add a new upgrade in game_data.gd, this is where you wire up what it
# actually does. Add a getter like the two below and read it where it matters.
func get_grab_chance() -> float:
	var level: int = upgrade_levels.get("grip_strength", 0)
	var bonus: float = level * GameData.UPGRADES["grip_strength"]["effect_per_level"]
	return clampf(GameData.BASE_GRAB_CHANCE + bonus, 0.0, GameData.MAX_GRAB_CHANCE)

func get_coin_multiplier() -> float:
	var level: int = upgrade_levels.get("coin_bonus", 0)
	return 1.0 + level * GameData.UPGRADES["coin_bonus"]["effect_per_level"]


# --- Upgrade helpers --------------------------------------------------------
func get_upgrade_level(id: String) -> int:
	return upgrade_levels.get(id, 0)

func get_upgrade_cost(id: String) -> int:
	var data: Dictionary = GameData.UPGRADES[id]
	var level: int = upgrade_levels.get(id, 0)
	return int(round(data["base_cost"] * pow(data["cost_growth"], level)))

func is_upgrade_maxed(id: String) -> bool:
	return upgrade_levels.get(id, 0) >= GameData.UPGRADES[id]["max_level"]

func can_afford_upgrade(id: String) -> bool:
	if is_upgrade_maxed(id):
		return false
	return coins >= get_upgrade_cost(id)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

# Used by the main menu's "New Game" — wipes progress back to defaults and
# saves immediately, so the old save is gone the moment the player confirms
# rather than lingering until the next coin/prize triggers a write.
func reset_game() -> void:
	coins = GameData.STARTING_COINS
	upgrade_levels = {}
	collection = {}
	total_grabs = 0
	last_run_coins = -1
	save_game()


func buy_upgrade(id: String) -> bool:
	if not can_afford_upgrade(id):
		return false
	coins -= get_upgrade_cost(id)
	upgrade_levels[id] = upgrade_levels.get(id, 0) + 1
	coins_changed.emit(coins)
	upgrade_purchased.emit(id, upgrade_levels[id])
	save_game()
	return true


# --- Save / load ------------------------------------------------------------
func save_game() -> void:
	last_played_unix = int(Time.get_unix_time_from_system())
	var data := {
		"version": SAVE_VERSION,
		"coins": coins,
		"upgrade_levels": upgrade_levels,
		"collection": collection,
		"total_grabs": total_grabs,
		"last_played_unix": last_played_unix,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file for writing.")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return  # first run — the defaults above are fine
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("Save file unreadable; starting fresh.")
		return
	coins = int(data.get("coins", GameData.STARTING_COINS))
	upgrade_levels = data.get("upgrade_levels", {})
	collection = data.get("collection", {})
	total_grabs = int(data.get("total_grabs", 0))
	last_played_unix = int(data.get("last_played_unix", 0))
	# GOTCHA: JSON stores every number as a float, so levels/counts come back as
	# floats (3.0 instead of 3). We coerce them back to ints here.
	for key in upgrade_levels.keys():
		upgrade_levels[key] = int(upgrade_levels[key])
	for key in collection.keys():
		collection[key] = int(collection[key])


# Save automatically when the app closes (desktop) or is backgrounded (tablet).
# We also save after every grab and purchase, so a crash loses almost nothing.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()
