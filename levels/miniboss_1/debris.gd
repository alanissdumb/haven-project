extends Area2D

const ACCEL = 70.0
const MAX_SPEED = 175.0
const LIFETIME = 10.0
const SWALLOW_DISTANCE = 300.0   # vanishes when it reaches the black hole
const SIZE = 22.0                # rock radius on screen
const HITBOX = 0.9               # hitbox radius, as a fraction of the rock

var target = null
var velocity = Vector2.ZERO
var age = 0.0
var art = null

func _ready():
	art = Asteroids.add_sprite(self, Asteroids.SMALL, SIZE)
	Asteroids.aim(art, velocity)
	var cs = $CollisionShape2D
	cs.shape = cs.shape.duplicate()
	cs.shape.radius = Asteroids.rock_radius(art) * HITBOX

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
	Asteroids.aim(art, velocity)

	for body in get_overlapping_bodies():
		if body.has_method("can_be_hit") and body.can_be_hit():
			body.take_damage(1)
			queue_free()
			return
