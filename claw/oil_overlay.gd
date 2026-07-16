extends Node2D
class_name OilOverlay
## Dripping black oil smeared across the machine's glass. A BLACK ("Oil Ball")
## grab calls splat(); a GOLDEN grab calls wipe_clean(). It's purely a visual
## griefer that obscures the pit for the REST of the run, getting worse with
## each oil ball.
##
## It keeps NO saved state — a new run is a fresh physics_playground instance,
## so the glass always starts clean; nothing has to reset it explicitly.
##
## Lives as a child of the pit `_world` (so it shares the pit's local space,
## whose origin is the pit's top-center) and is added ABOVE the balls and claw
## so the oil sits "on the glass" in front of everything in the pit.

# Glass area in _world-local space. Reaches a little past the pit walls but
# stops short of the top timer bar and the bottom control buttons, which live
# outside the pit.
const _SIDE_MARGIN := 20.0
const _GLASS_TOP := -18.0

const _OIL := Color(0.05, 0.055, 0.07)   # near-black with a faint cool tint
const _SHEEN := Color(0.55, 0.6, 0.68)   # wet-looking highlight down a drip

var _film := 0.0                     # current whole-glass darkening (0..1)
var _film_target := 0.0
var _drips: Array[Dictionary] = []   # each: {x, w, len, target, speed}
var _blobs: Array[Dictionary] = []   # each: {x, y, r} smears pooled at the top
var _splats := 0                     # oil balls collected this run (read by tests)


func _ready() -> void:
	set_process(false)  # nothing to animate until the first splat


# Called when an oil ball is collected: darken the glass a notch and add a
# fresh set of drips that run down over the next moment.
func splat() -> void:
	_splats += 1
	_film_target = minf(_film_target + GameData.OIL_FILM_PER_SPLAT, GameData.OIL_FILM_MAX)

	var left := -GameData.PIT_WIDTH / 2.0 - _SIDE_MARGIN
	var right := GameData.PIT_WIDTH / 2.0 + _SIDE_MARGIN
	# Keep the rounded tip on the glass: cap how far a drip can run.
	var max_len := (GameData.PIT_HEIGHT + 10.0) - _GLASS_TOP - 30.0

	for i in GameData.OIL_DRIPS_PER_SPLAT:
		var w := randf_range(12.0, 30.0)
		_drips.append({
			"x": randf_range(left + w, right - w),
			"w": w,
			"len": randf_range(6.0, 24.0),          # starts as a short bead...
			"target": randf_range(90.0, max_len),   # ...then runs down to here
			"speed": randf_range(120.0, 260.0),
		})
	for i in 2:
		_blobs.append({
			"x": randf_range(left + 30.0, right - 30.0),
			"y": randf_range(_GLASS_TOP + 8.0, _GLASS_TOP + 54.0),
			"r": randf_range(28.0, 64.0),
		})

	set_process(true)
	queue_redraw()


# Called when a golden ball is collected: the squeegee moment — every oil ball's
# work is undone and the glass is clear again.
func wipe_clean() -> void:
	_drips.clear()
	_blobs.clear()
	_splats = 0
	_film = 0.0
	_film_target = 0.0
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	var busy := false
	_film = move_toward(_film, _film_target, delta * 1.5)
	if not is_equal_approx(_film, _film_target):
		busy = true
	for d in _drips:
		if d["len"] < d["target"]:
			d["len"] = move_toward(d["len"], d["target"], d["speed"] * delta)
			busy = true
	queue_redraw()
	if not busy:
		set_process(false)  # settled — stop redrawing until the next splat


func _draw() -> void:
	if _film <= 0.001 and _drips.is_empty() and _blobs.is_empty():
		return

	var left := -GameData.PIT_WIDTH / 2.0 - _SIDE_MARGIN
	var width := GameData.PIT_WIDTH + 2.0 * _SIDE_MARGIN
	var bottom := GameData.PIT_HEIGHT + 10.0

	# 1) Whole-glass darkening film.
	if _film > 0.001:
		draw_rect(Rect2(left, _GLASS_TOP, width, bottom - _GLASS_TOP),
			Color(_OIL.r, _OIL.g, _OIL.b, _film))

	# 2) Oil pooled along the top edge that the drips run out of.
	var band_alpha := minf(0.9, _film + 0.35)
	draw_rect(Rect2(left, _GLASS_TOP, width, 34.0),
		Color(_OIL.r, _OIL.g, _OIL.b, band_alpha))

	# 3) Smears near the top.
	for b in _blobs:
		draw_circle(Vector2(b["x"], b["y"]), b["r"], Color(_OIL.r, _OIL.g, _OIL.b, 0.9))

	# 4) Running drips: an opaque stem, a rounded bead at the tip, and a thin
	#    sheen down one side so the oil reads as wet.
	for d in _drips:
		var x: float = d["x"]
		var w: float = d["w"]
		var run_len: float = d["len"]
		draw_rect(Rect2(x - w / 2.0, _GLASS_TOP, w, run_len), _OIL)
		draw_circle(Vector2(x, _GLASS_TOP + run_len), w * 0.6, _OIL)
		draw_rect(Rect2(x - w * 0.32, _GLASS_TOP, w * 0.16, run_len),
			Color(_SHEEN.r, _SHEEN.g, _SHEEN.b, 0.22))
