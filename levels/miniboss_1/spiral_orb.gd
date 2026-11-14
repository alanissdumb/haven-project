extends Area2D
var color = Color(1.0, 0.45, 0.25)
const RADIUS = 14.0
const LIFETIME = 7.0

var velocity = Vector2.ZERO
var age = 0.0

func _physics_process(delta):
	position += velocity * delta
	age += delta
	if age > LIFETIME:
		queue_free()
		return

	for body in get_overlapping_bodies():
		if body.has_method("can_be_hit") and body.can_be_hit():
			body.take_damage(1)
			queue_free()
			return

func _draw():
	draw_circle(Vector2.ZERO, RADIUS, color)
	draw_circle(Vector2.ZERO, RADIUS * 0.5, Color(1.0, 0.95, 0.85))
