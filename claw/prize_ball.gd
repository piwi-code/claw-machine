extends RigidBody2D
class_name PrizeBall
## A physics ball sitting in the claw machine pit. Placeholder art — just a
## flat colored circle — until real prize sprites exist.

var color: Color = Color(0.9, 0.6, 0.3)


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
	draw_circle(Vector2.ZERO, GameData.BALL_RADIUS, color)
