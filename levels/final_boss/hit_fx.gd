extends Node2D

var big = false
var color = Color(1.0, 0.8, 0.4)

var age = 0.0
var life = 0.3
var spin_offset = 0.0

func _ready():
	z_index = 5
	life = 0.5 if big else 0.25
	spin_offset = randf() * TAU
	var cam = get_viewport().get_camera_2d()
	if cam:
		scale = Vector2.ONE / cam.zoom       # same size on screen at any zoom

func _process(delta):
	age += delta
	if age >= life:
		queue_free()
		return
	queue_redraw()

func _draw():
	var t = age / life
	var e = 1.0 - pow(1.0 - t, 3.0)    # fast start, slow finish
	var fade = 1.0 - t
	var ray_col = Color(color.lightened(0.5), fade)

	if big:
		draw_circle(Vector2.ZERO, 46.0 * (1.0 - t * 0.6), Color(1, 1, 1, fade * fade))
		draw_arc(Vector2.ZERO, 30.0 + 150.0 * e, 0, TAU, 64, Color(color, fade), 3.0 + 7.0 * fade)
		draw_arc(Vector2.ZERO, 20.0 + 90.0 * e, 0, TAU, 48, Color(1, 1, 1, fade * 0.7), 2.0)
		for i in range(12):
			var d = Vector2.RIGHT.rotated(spin_offset + i * TAU / 12.0)
			var inner = 40.0 + 90.0 * e
			draw_line(d * inner, d * (inner + 10.0 + 60.0 * fade), ray_col, 3.0 + 2.0 * fade)
	else:
		draw_circle(Vector2.ZERO, 14.0 * (1.0 - t), Color(1, 1, 1, fade))
		draw_arc(Vector2.ZERO, 10.0 + 36.0 * e, 0, TAU, 32, Color(color, fade), 2.0 + 2.0 * fade)
		for i in range(6):
			var d = Vector2.RIGHT.rotated(spin_offset + i * TAU / 6.0)
			var inner = 12.0 + 26.0 * e
			draw_line(d * inner, d * (inner + 3.0 + 10.0 * fade), ray_col, 2.0)
