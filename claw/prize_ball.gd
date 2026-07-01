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
	var color: Color = GameData.PRIZES.get(prize_id, {}).get("color", Color.WHITE)
	draw_circle(Vector2.ZERO, GameData.BALL_RADIUS, color)
