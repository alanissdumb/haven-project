extends Area2D

const ACCEL = 380.0         # pull toward the sun (was 220)
const MAX_SPEED = 650.0      # speed cap (was 500)
const HOMING = 160.0         # pull toward the player
const MIN_ROCK = 24.0        # all 21 asteroids: the smallest art gets this rock radius,
const MAX_ROCK = 64.0        # the biggest gets this (the old ball was 40)
const HITBOX = 0.9           # hitbox radius, as a fraction of the rock
const SUN_RADIUS = 300.0     # match the boss's radius

var target = null
var velocity = Vector2.ZERO
var exploding = false
var spark = 0.0
var art = null
var ball_radius = 40.0       # rock radius on screen, set from the art

func _ready():
	art = Asteroids.add_sprite_ranged(self, Asteroids.ALL, MIN_ROCK, MAX_ROCK)
	Asteroids.aim(art, velocity)
	ball_radius = Asteroids.rock_radius(art)
	var cs = $CollisionShape2D
	cs.shape = cs.shape.duplicate()
	cs.shape.radius = ball_radius * HITBOX

func _physics_process(delta):
	if exploding:
		return
	if not is_instance_valid(target):
		queue_free()
		return
	for body in get_overlapping_bodies():
		if body.has_method("can_be_hit") and body.can_be_hit():
			body.take_damage(1)
			explode()
			return
	var to_target = target.global_position - global_position
	if to_target.length() <= SUN_RADIUS:
		explode()
		return

	# Gravity toward the sun
	velocity += to_target.normalized() * ACCEL * delta

	# Slight homing toward the player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var to_player = player.global_position - global_position
		velocity += to_player.normalized() * HOMING * delta

	velocity = velocity.limit_length(MAX_SPEED)
	position += velocity * delta
	Asteroids.aim(art, velocity)

func _process(_delta):
	queue_redraw()

func _draw():
	if exploding:
		for i in range(8):
			var dir = Vector2.RIGHT.rotated(i * TAU / 8.0)
			var from = dir * (ball_radius * 0.6 + spark * 70.0)
			var to = dir * (ball_radius * 1.5 + spark * 100.0)
			draw_line(from, to, Color(1, 1, 0.7, 1.0 - spark), 4.0)

func explode():
	exploding = true
	art.hide()
	$CollisionShape2D.set_deferred("disabled", true)
	var tween = create_tween()
	tween.tween_property(self, "spark", 1.0, 0.3)
	tween.tween_callback(queue_free)
