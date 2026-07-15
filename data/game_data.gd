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


# --- CLAW PHYSICS (playground) -----------------------------------------------
# Tuning for the physics-based claw prototype (claw/physics_playground.gd and
# the headless tests in tests/). Nothing here talks to coins/prizes yet — it's
# just movement/grab feel. Kept as one shared source so the tests can build
# the same pit the real game does, instead of duplicating these numbers.
const PIT_WIDTH := 600.0            # px, inside width of the pit
const PIT_HEIGHT := 420.0           # px, floor position measured from the ceiling
const CEILING_Y := 40.0             # px, where the claw carriage rides
const CLAW_MOVE_SPEED := 220.0      # px/sec, horizontal carriage speed
const CLAW_DROP_SPEED := 260.0      # px/sec, descending speed
const CLAW_RISE_SPEED := 200.0      # px/sec, ascending speed
const CLAW_MAX_DROP_DEPTH := 380.0  # px, how far the arm can extend down.
                                     # Balls settle near PIT_HEIGHT - 10 - BALL_RADIUS
                                     # (~392); keep this within CLAW_GRAB_RADIUS +
                                     # BALL_RADIUS of that so a resting ball is reachable.
const CLAW_GRAB_RADIUS := 26.0      # px, reach of the grab area at the claw tip
const BALL_RADIUS := 18.0           # px
const BALL_COUNT := 24              # how many balls fill the pit at the start of a run


# --- CLAW RUN (the shop <-> machine loop) -------------------------------------
# One "run" = one timed go at the machine: the pit fills with BALL_COUNT random
# balls, the timer bar drains over RUN_SECONDS, and the run ends when time runs
# out, the pit is cleared, or the player presses END. These live here (not in
# the playground script) so shop power-ups can eventually modify them — more
# time, more balls, better prize odds.
const RUN_SECONDS := 20.0           # length of one claw run
const RUN_END_PAUSE_SECONDS := 3.0  # how long the "run over" sign shows before
                                     # returning to the shop


# --- UI SKIN (arcade pastel) --------------------------------------------------
# Colors and style numbers lifted from the "Game Screen — Arcade Pastel" design
# in the Claude Design project (screens/game-screen.html). Change a color here,
# press Play, and the game repaints — nothing visual is hard-coded in scripts.
const UI_FONT := "res://assets/fonts/fredoka_semibold.ttf"
const PRIZE_TOAST_SECONDS := 2.5    # how long the "you won!" note lingers

const SKIN := {
	# background: soft top-to-bottom pastel sky, warm floor strip
	"bg_colors": [Color("f6d9e6"), Color("e9d3f2"), Color("cdeaf0"), Color("bfe6da")],
	"bg_offsets": [0.0, 0.38, 0.72, 1.0],
	"floor_top": Color("fef2df"),
	"floor_bottom": Color("fbe3c2"),
	"floor_height": 130.0,

	# cabinet / pit hardware purple
	"cabinet": Color("8f7cc9"),

	# round arrow buttons (mint)
	"arrow_bg": Color("bff0da"),
	"arrow_edge": Color("8fd8b4"),
	"arrow_text": Color("4d7a63"),

	# big DROP button (coral)
	"drop_bg": Color("ff9e83"),
	"drop_edge": Color("e07659"),
	"drop_text": Color("7a3521"),

	# cream pills: coin counter + prize toast
	"pill_bg": Color("fff8ec"),
	"pill_edge": Color("ecd9b0"),
	"pill_text": Color("7a5a20"),
	"coin_fill": Color("ffd76a"),
	"coin_edge": Color("f0b93c"),

	# status text over the pastel background
	"status_text": Color("5a4670"),

	# marquee badge (menu title / machine sign)
	"marquee_bg": Color("ff9ec4"),
	"marquee_border": Color("ffffff"),
	"marquee_text": Color("ffffff"),
}
