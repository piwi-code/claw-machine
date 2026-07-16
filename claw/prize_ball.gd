extends RigidBody2D
class_name PrizeBall
## A physics ball sitting in the claw machine pit. `prize_id` decides both
## what it pays out (GameData.PRIZES) and its placeholder look — a flat
## colored circle until real prize sprites exist.

var prize_id: String = ""


func _ready() -> void:
	add_to_group("balls")

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = GameData.BALL_RADIUS
	shape.shape = circle
	add_child(shape)

	var material := PhysicsMaterial.new()
	material.friction = 0.8
	material.bounce = 0.05
	physics_material_override = material


func _draw() -> void:
	var prize: Dictionary = GameData.PRIZES.get(prize_id, {})
	var r := GameData.BALL_RADIUS
	draw_circle(Vector2.ZERO, r, prize.get("color", Color.WHITE))

	# Special balls get a little gloss so they read as "not an ordinary prize"
	# even before real art exists: the golden jackpot gleams, the oil ball has
	# a faint wet sheen.
	match prize.get("effect", ""):
		"shine":
			draw_circle(Vector2(-r * 0.32, -r * 0.32), r * 0.28, Color(1, 1, 1, 0.85))
		"oil":
			draw_circle(Vector2(-r * 0.3, -r * 0.3), r * 0.22, Color(0.5, 0.52, 0.6, 0.5))
