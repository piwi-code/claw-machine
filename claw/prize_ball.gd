extends RigidBody2D
class_name PrizeBall
## A physics ball sitting in the claw machine pit. `prize_id` decides both
## what it pays out (GameData.PRIZES) and its placeholder look — a flat
## colored circle until real prize sprites exist.

const OUTLINE_WIDTH := 3.0  # px, thickness of a prize's optional rim

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
	draw_circle(Vector2.ZERO, GameData.BALL_RADIUS, prize.get("color", Color.WHITE))

	# Optional rim (the Dalek's dark-grey outline). Inset by half the stroke
	# width so the outer edge lands on BALL_RADIUS instead of spilling past it.
	var outline: Variant = prize.get("outline", null)
	if outline != null:
		draw_arc(Vector2.ZERO, GameData.BALL_RADIUS - OUTLINE_WIDTH / 2.0,
			0.0, TAU, 32, outline, OUTLINE_WIDTH, true)
