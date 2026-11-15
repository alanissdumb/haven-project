extends Area2D

const ACCEL = 380.0
const MAX_SPEED = 700.0
const LIFETIME = 10.0
const SWALLOW_DISTANCE = 750.0   # vanishes when it reaches the black hole
const MIN_ROCK = 18.0            # all 21 asteroids: the smallest art gets this rock radius,
const MAX_ROCK = 56.0            # the biggest gets this (the old debris was 22)
const HITBOX = 0.9               # hitbox radius, as a fraction of the rock

var target = null
var velocity = Vector2.ZERO
var age = 0.0
var art = null

func _ready():
	art = Asteroids.add_sprite_ranged(self, Asteroids.ALL, MIN_ROCK, MAX_ROCK)
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
