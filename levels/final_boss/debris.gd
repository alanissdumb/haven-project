extends Area2D

const ACCEL = 380.0
const MAX_SPEED = 700.0
const LIFETIME = 10.0
const SWALLOW_DISTANCE = 750.0   # vanishes when it reaches the black hole
const SIZE = 22.0

var target = null
var velocity = Vector2.ZERO
var age = 0.0
var spin_speed = 0.0
var pts = PackedVector2Array()

func _ready():
	spin_speed = randf_range(-3.0, 3.0)
	for i in range(8):
		var a = i * TAU / 8.0
		pts.append(Vector2.RIGHT.rotated(a) * SIZE * randf_range(0.7, 1.15))

func _physics_process(delta):
	age += delta
	if age > LIFETIME or not is_instance_valid(target):
		queue_free()
		return

	var to_target = target.global_position - global_position
	if to_target.length() < SWALLOW_DISTANCE:
		queue_free()
		return

	velocity += to_target.normalized() * ACCEL * delta
	velocity = velocity.limit_length(MAX_SPEED)
	position += velocity * delta
	rotation += spin_speed * delta

	for body in get_overlapping_bodies():
		if body.has_method("can_be_hit") and body.can_be_hit():
			body.take_damage(1)
			queue_free()
			return

func _draw():
	draw_colored_polygon(pts, Color(0.5, 0.3, 0.22))
	var outline = pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, Color(1.0, 0.6, 0.3), 2.0)
