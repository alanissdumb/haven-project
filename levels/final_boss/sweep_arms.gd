extends Node2D

const ARMS = 5
const LENGTH = 4500.0
const WIDTH = 95.0
const WARN_TIME = 0.8
const ACTIVE_TIME = 6.0
const TURN_SPEED = 0.25      # radians per second
const REVERSE_PAUSE = 0.5    # arms freeze and flash, then spin the other way

var timer = 0.0
var angle = 0.0
var dir = 1.0
var reversed = false
var pause_left = 0.0

func _ready():
	angle = randf() * TAU
	dir = [-1.0, 1.0].pick_random()

func _physics_process(delta):
	timer += delta
	if timer >= WARN_TIME:
		if pause_left > 0.0:
			pause_left -= delta
		else:
			angle += TURN_SPEED * dir * delta
		if not reversed and timer >= WARN_TIME + ACTIVE_TIME / 2.0:
			reversed = true
			dir = -dir
			pause_left = REVERSE_PAUSE
		check_hit()
	if timer >= WARN_TIME + ACTIVE_TIME:
		queue_free()

func check_hit():
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.can_be_hit():
		return
	var p = player.global_position - global_position
	for k in range(ARMS):
		var d = Vector2.RIGHT.rotated(angle + k * TAU / ARMS)
		var along = p.dot(d)
		var across = abs(p.cross(d))
		if along > 0.0 and along < LENGTH and across < WIDTH / 2.0 + 14.0:
			player.take_damage(1)
			return

func _process(_delta):
	queue_redraw()

func _draw():
	var active = timer >= WARN_TIME
	var frozen = pause_left > 0.0
	for k in range(ARMS):
		var d = Vector2.RIGHT.rotated(angle + k * TAU / ARMS)
		if active:
			var glow = Color(1, 0.4, 0.8, 0.35)
			if frozen:
				glow = Color(1, 0.9, 0.4, 0.55)   # yellow flash: about to reverse
			draw_line(Vector2.ZERO, d * LENGTH, glow, WIDTH)
			draw_line(Vector2.ZERO, d * LENGTH, Color(1, 0.95, 1.0), WIDTH * 0.3)
		else:
			var pulse = 0.4 + 0.4 * sin(timer * 25.0)
			draw_line(Vector2.ZERO, d * LENGTH, Color(1, 0.5, 0.9, pulse), 3.0)
