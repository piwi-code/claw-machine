class_name GameData
## Pure DATA for the game. No logic lives here.
##
## This is the "tweak the numbers" file — the safe place for you and your
## daughter to experiment. Change a value, press Play, see what happens.
## Nothing here can break the game's plumbing, so poke at it freely.
##
## It's a global class (note the `class_name` line above), so any script can
## read it as `GameData.PRIZES`, `GameData.UPGRADES`, etc. — no setup needed.


# --- PRIZES -----------------------------------------------------------------
# Each prize has a friendly name, the coins it pays out, and a "weight".
# Higher weight = grabbed more often. Rare prizes get a LOW weight and a BIG
# payout. (teddy is common and cheap; the sparkle dragon is rare and juicy.)
#
# LATER: this is where your daughter's drawings go. Swap "color" for a texture
# path to her artwork, and let her name each plushie.
const PRIZES := {
	"teddy":  { "name": "Teddy Bear",     "value": 5,  "weight": 60, "color": Color("c08552") },
	"bunny":  { "name": "Floppy Bunny",   "value": 12, "weight": 25, "color": Color("e8c1c5") },
	"ducky":  { "name": "Rubber Ducky",   "value": 20, "weight": 10, "color": Color("f4d35e") },
	"dragon": { "name": "Sparkle Dragon", "value": 75, "weight": 5,  "color": Color("8ac7db") },
}


# --- UPGRADES ---------------------------------------------------------------
# Cost grows each time you buy it:   cost(level) = base_cost * (cost_growth ^ level)
#
# To ADD an upgrade: copy a block, give it a new id (the key), and pick numbers.
# It will automatically appear in the shop UI. The one extra step is teaching the
# game what the upgrade DOES — see the matching note in game_state.gd.
const UPGRADES := {
	"grip_strength": {
		"name": "Grip Strength",
		"description": "Better chance to grab a prize.",
		"base_cost": 10,
		"cost_growth": 1.6,
		"max_level": 20,
		"effect_per_level": 0.03,   # +3% grab chance per level
	},
	"coin_bonus": {
		"name": "Shiny Coins",
		"description": "Every prize is worth more coins.",
		"base_cost": 25,
		"cost_growth": 1.8,
		"max_level": 15,
		"effect_per_level": 0.10,   # +10% coins per level
	},
}


# --- TUNING -----------------------------------------------------------------
const BASE_GRAB_CHANCE := 0.45   # 45% chance to grab before any upgrades
const MAX_GRAB_CHANCE := 0.95    # never guaranteed — keep a little suspense
const STARTING_COINS := 0
