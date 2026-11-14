extends Area2D

const LIFETIME = 14.0
const KINDS = ["health", "rapid", "dash", "double", "speed"]

var kind = ""      # "" = mystery box (random effect), "super" = guaranteed overcharge
var age = 0.0

func _ready():
	add_to_group("powerup")
	if kind == "super":
		add_to_group("super_powerup")
	body_entered.connect(_on_body_entered)

func get_life():
	return LIFETIME * (1.5 if kind == "super" else 1.0)

func _process(delta):
	age += delta
	if age >= get_life():
		queue_free()
		return
	var cam = get_viewport().get_camera_2d()
	if cam:
		scale = Vector2.ONE / cam.zoom    # stays the same size on screen at any zoom
	queue_redraw()

func _on_body_entered(body):
	if not body.has_method("apply_powerup"):
		return
	var picked = kind
	if picked == "":
		var pool = KINDS.duplicate()
		if body.hp >= body.MAX_HP:
			pool.erase("health")      # no wasted heal at full health
		picked = pool.pick_random()
	body.apply_powerup(picked)
	queue_free()

func _draw():
	var blink = 1.0
	if age > get_life() - 3.0:
		blink = 0.4 + 0.6 * abs(sin(age * 12.0))   # flickers before it disappears
	var c = Vector2(0, sin(age * 3.0) * 4.0)

	if kind == "super":
		var pts = PackedVector2Array()
		for i in range(10):
			var r = 34.0 if i % 2 == 0 else 15.0
			pts.append(c + Vector2.UP.rotated(i * TAU / 10.0 + age) * r)
		draw_circle(c, 44.0, Color(1.0, 0.85, 0.2, 0.25 * blink))
		draw_colored_polygon(pts, Color(1.0, 0.85, 0.2, blink))
	else:
		draw_circle(c, 36.0, Color(0.6, 0.4, 1.0, 0.25 * blink))
		draw_circle(c, 26.0, Color(0.35, 0.2, 0.7, blink))
		draw_arc(c, 26.0, 0, TAU, 32, Color(0.85, 0.75, 1.0, blink), 3.0)
		draw_string(ThemeDB.fallback_font, c + Vector2(-20, 11), "?", HORIZONTAL_ALIGNMENT_CENTER, 40, 32, Color(1, 1, 1, blink))
