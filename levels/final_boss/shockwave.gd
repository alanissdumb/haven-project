extends Node2D

const WARN_TIME = 0.9        # telegraph before it expands
const SPEED = 450.0          # faster than the ship (400), so you can't outrun it
const THICKNESS = 36.0
const START_RADIUS = 300.0   # planet radius
const MAX_RADIUS = 1600.0

var radius = START_RADIUS
var timer = 0.0
var hit_done = false
var ring = null

func _ready():
	ring = FX.spawn("sun_fire_ring", self)
	ring.hide()

func _physics_process(delta):
	timer += delta
	if timer < WARN_TIME:
		return

	radius += SPEED * delta

	if not hit_done:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.can_be_hit():
			var dist = player.global_position.distance_to(global_position)
			if abs(dist - radius) <= THICKNESS / 2.0:
				player.take_damage(1)
				hit_done = true

	if radius > MAX_RADIUS:
		queue_free()

func _process(_delta):
	ring.visible = timer >= WARN_TIME
	ring.scale = Vector2.ONE * FX.scale_for("sun_fire_ring", radius)
	queue_redraw()

func _draw():
	if timer < WARN_TIME:
		var t = timer / WARN_TIME
		var pulse = 0.5 + 0.5 * sin(timer * 20.0)
		draw_arc(Vector2.ZERO, START_RADIUS + 6.0, 0, TAU, 128, Color(1, 0.4, 0.3, 0.3 + 0.6 * pulse * t), 4.0)
	# once it fires, the sun_fire_ring sprite is the visual
