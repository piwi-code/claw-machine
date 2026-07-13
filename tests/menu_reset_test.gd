extends Node2D
## HEADLESS REGRESSION TEST — GameState.has_save() / reset_game(), the logic
## behind the main menu's Continue vs New Game choice.
##
## Runs synchronously in _ready(): no physics to settle, so there's no need
## to wait a frame. tests/run_headless.sh runs this under a throwaway $HOME,
## so it never touches the real save file.


func _ready() -> void:
	if GameState.has_save():
		_finish(false, "FAIL: fresh $HOME should have no save yet")
		return

	GameState.add_coins(50)
	GameState.upgrade_levels["grip_strength"] = 3
	GameState.register_prize("teddy")
	GameState.save_game()

	if not GameState.has_save():
		_finish(false, "FAIL: has_save() should be true right after save_game()")
		return

	GameState.reset_game()

	if GameState.coins != GameData.STARTING_COINS:
		_finish(false, "FAIL: reset_game() left coins=%d, expected %d" % [
			GameState.coins, GameData.STARTING_COINS
		])
		return
	if not GameState.upgrade_levels.is_empty():
		_finish(false, "FAIL: reset_game() left upgrade_levels=%s, expected empty" % [
			GameState.upgrade_levels
		])
		return
	if not GameState.collection.is_empty():
		_finish(false, "FAIL: reset_game() left collection=%s, expected empty" % [
			GameState.collection
		])
		return
	if not GameState.has_save():
		_finish(false, "FAIL: reset_game() should still leave a save file behind")
		return

	_finish(true, "PASS: reset_game() cleared coins/upgrades/collection and re-saved")


func _finish(passed: bool, message: String) -> void:
	if passed:
		print(message)
	else:
		printerr(message)
	get_tree().quit(0 if passed else 1)
