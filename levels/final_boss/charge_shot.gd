extends Area2D

const SPEED = 1100.0
const LIFETIME = 6.0
const HIT_FX = preload("res://levels/final_boss/hit_fx.tscn")

var direction = Vector2.UP
var damage = 20
var age = 0.0
var hit_list = []

func _ready():
	area_entered.connect(_on_area_entered)
	var cam = get_viewport().get_camera_2d()
	if cam:
		scale = Vector2.ONE * sqrt(1.0 / cam.zoom.x)   # bigger when the camera is zoomed out

func _physics_process(delta):
	position += direction * SPEED * delta
	age += delta
	if age > LIFETIME:
		queue_free()
	queue_redraw()

func _on_area_entered(area):
	if area in hit_list or not area.has_method("take_damage"):
		return
	hit_list.append(area)
	area.take_damage(damage)

	var fx = HIT_FX.instantiate()
	fx.global_position = global_position
	fx.big = true
	fx.color = Color(1.0, 0.85, 0.4)
	if area.get("absorbing") == true:
		fx.color = Color(0.4, 0.9, 1.0)
	get_parent().add_child(fx)

	if area.is_in_group("boss"):
		queue_free()      # stops on the boss, but pierces minions

func _draw():
	var pulse = 0.5 + 0.5 * sin(age * 24.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-20, -22), Vector2(-190, 0), Vector2(-20, 22)]), Color(1.0, 0.8, 0.3, 0.45))
	draw_colored_polygon(PackedVector2Array([Vector2(-20, -11), Vector2(-120, 0), Vector2(-20, 11)]), Color(1.0, 0.95, 0.75, 0.8))
	draw_circle(Vector2.ZERO, 42.0 + 3.0 * pulse, Color(1.0, 0.8, 0.3, 0.22))
	draw_circle(Vector2.ZERO, 28.0, Color(1.0, 0.85, 0.4))
	draw_circle(Vector2.ZERO, 16.0, Color.WHITE)
