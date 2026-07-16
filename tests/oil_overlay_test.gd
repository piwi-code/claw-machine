extends Node2D
## HEADLESS UNIT TEST for OilOverlay's bookkeeping — the golden ball's "wipe
## the glass" and the oil ball's "keep smearing, but not past the cap" logic,
## with no physics or claw in the loop so it can't go flaky.

func _ready() -> void:
	var oil := OilOverlay.new()
	add_child(oil)

	# Two oil balls: splats stack and the film darkens, but never past the cap.
	oil.splat()
	oil.splat()
	if oil._splats != 2:
		_fail("expected 2 splats, got %d" % oil._splats)
		return
	if oil._film_target <= 0.0:
		_fail("film should darken after a splat, got %f" % oil._film_target)
		return
	if oil._film_target > GameData.OIL_FILM_MAX + 0.0001:
		_fail("film %f exceeded cap %f" % [oil._film_target, GameData.OIL_FILM_MAX])
		return

	# Golden ball: the glass wipes fully clean.
	oil.wipe_clean()
	if oil._splats != 0 or oil._film_target != 0.0 or not oil._drips.is_empty():
		_fail("wipe_clean left residue: splats=%d film=%f drips=%d" % [
			oil._splats, oil._film_target, oil._drips.size()])
		return

	print("PASS: oil overlay stacks splats to the cap and wipes clean")
	get_tree().quit(0)


func _fail(msg: String) -> void:
	printerr("FAIL: " + msg)
	get_tree().quit(1)
