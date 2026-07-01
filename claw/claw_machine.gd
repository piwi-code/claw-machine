extends Node
class_name ClawMachine
## THE CLAW. The heart of the game loop.
##
## Call attempt_grab() and it does one drop: rolls the dice, and on a win picks
## a prize, pays out coins, and records it (all through GameState). It returns a
## little result dictionary you can use to drive animation, sound, or screen FX.
##
## Deliberately tiny and self-contained — this is the piece you'll wrap in juicy
## visuals later (the claw lowering, the prize popping out, the coin shower).


# Returns one of:
#   { "success": true, "prize_id": "bunny", "coins_awarded": 13 }
#   { "success": false }
func attempt_grab() -> Dictionary:
	GameState.total_grabs += 1

	# Did we grab anything? Grip Strength upgrades nudge this in your favour.
	if randf() > GameState.get_grab_chance():
		GameState.grab_failed.emit()
		return { "success": false }

	# We caught something — pick which prize, weighted by rarity, and award it.
	var prize_id := GameState.pick_weighted_prize()
	var coins_awarded := GameState.award_prize(prize_id)

	return { "success": true, "prize_id": prize_id, "coins_awarded": coins_awarded }
