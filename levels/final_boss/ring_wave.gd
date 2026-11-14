extends Node2D

# The boss sets these before adding the ring to the scene
var start_radius = 340.0
var speed = 300.0
var warn_time = 1.0
var thickness = 40.0
var max_radius = 5000
var gap_center = 0.0      # angle of the safe gap
var gap_width = 0.0       # gap size in radians (0 = no gap)
var color = Color(1.0, 0.6, 0.25)

var radius = 0.0
var timer = 0.0
var hit_done = false

func _ready():
	radius = start_radius

func _physics_process(delta):
	timer += delta
	if timer < warn_time:
		return
	radius += speed * delta
	if not hit_done:
		check_hit()
	if radius > max_radius:
		queue_free()

func check_hit():
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.can_be_hit():
		return
	var offset = player.global_position - global_position
	if abs(offset.length() - radius) > thickness / 2.0 + 16.0:
		return
	if gap_width > 0.0 and abs(angle_difference(gap_center, offset.angle())) < gap_width / 2.0:
		return
	player.take_damage(1)
	hit_done = true

func _process(_delta):
	queue_redraw()

func _draw():
	var gap_start = gap_center - gap_width / 2.0
	var gap_end = gap_center + gap_width / 2.0

	if timer < warn_time:
		var pulse = 0.5 + 0.5 * sin(timer * 18.0)
		draw_arc(Vector2.ZERO, start_radius + 6.0, gap_end, gap_start + TAU, 192, Color(color, 0.25 + 0.55 * pulse), 4.0)
		if gap_width > 0.0:
			draw_arc(Vector2.ZERO, start_radius + 6.0, gap_start, gap_end, 48, Color(0.4, 1.0, 0.6, 0.8), 6.0)
		return

	draw_arc(Vector2.ZERO, radius, gap_end, gap_start + TAU, 256, Color(color, 0.35), thickness)
	draw_arc(Vector2.ZERO, radius, gap_end, gap_start + TAU, 256, Color(1, 0.95, 0.8), thickness * 0.2)
	if gap_width > 0.0:
		draw_arc(Vector2.ZERO, radius, gap_start, gap_end, 64, Color(0.4, 1.0, 0.6, 0.25), 6.0)
