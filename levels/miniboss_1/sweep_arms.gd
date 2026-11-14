extends Node2D

const ARMS = 4
const LENGTH = 1500.0
const WIDTH = 34.0
const WARN_TIME = 0.8
const ACTIVE_TIME = 6.0
const TURN_SPEED = 0.45     # radians per second

var timer = 0.0
var angle = 0.0
var dir = 1.0

func _ready():
	angle = randf() * TAU
	dir = [-1.0, 1.0].pick_random()

func _physics_process(delta):
	timer += delta
	if timer >= WARN_TIME:
		angle += TURN_SPEED * dir * delta
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
	for k in range(ARMS):
		var d = Vector2.RIGHT.rotated(angle + k * TAU / ARMS)
		if active:
			draw_line(Vector2.ZERO, d * LENGTH, Color(1, 0.4, 0.8, 0.35), WIDTH)
			draw_line(Vector2.ZERO, d * LENGTH, Color(1, 0.95, 1.0), WIDTH * 0.3)
		else:
			var pulse = 0.4 + 0.4 * sin(timer * 25.0)
			draw_line(Vector2.ZERO, d * LENGTH, Color(1, 0.5, 0.9, pulse), 3.0)
