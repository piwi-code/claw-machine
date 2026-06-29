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

	# We caught something — pick which prize, weighted by rarity.
	var prize_id := _pick_weighted_prize()
	var prize: Dictionary = GameData.PRIZES[prize_id]
	var coins_awarded := int(round(prize["value"] * GameState.get_coin_multiplier()))

	GameState.register_prize(prize_id)
	GameState.add_coins(coins_awarded)
	GameState.save_game()

	return { "success": true, "prize_id": prize_id, "coins_awarded": coins_awarded }


# Picks a random prize id, respecting each prize's "weight" (rarity).
func _pick_weighted_prize() -> String:
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
