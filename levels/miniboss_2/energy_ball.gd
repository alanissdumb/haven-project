extends Area2D

const ACCEL = 450.0          # pull toward the sun (was 220)
const MAX_SPEED = 680.0      # speed cap (was 500)
const HOMING = 250.0         # pull toward the player
const BALL_RADIUS = 64     
const SUN_RADIUS = 130.0     # match Saturn's body radius

var target = null
var velocity = Vector2.ZERO
var exploding = false
var spark = 0.0

func _ready():
	pass

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

func _process(_delta):
	queue_redraw()

func _draw():
	if exploding:
		for i in range(8):
			var dir = Vector2.RIGHT.rotated(i * TAU / 8.0)
			var from = dir * (BALL_RADIUS * 0.6 + spark * 70.0)
			var to = dir * (BALL_RADIUS * 1.5 + spark * 100.0)
			draw_line(from, to, Color(1, 1, 0.7, 1.0 - spark), 4.0)
	else:
		draw_circle(Vector2.ZERO, BALL_RADIUS, Color(0.4, 0.8, 1.0))
		draw_circle(Vector2.ZERO, BALL_RADIUS * 0.55, Color.WHITE)

func explode():
	exploding = true
	$CollisionShape2D.set_deferred("disabled", true)
	var tween = create_tween()
	tween.tween_property(self, "spark", 1.0, 0.3)
	tween.tween_callback(queue_free)
