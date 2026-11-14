extends Area2D

@export var max_hp = 25
@export var width_radius: float = 100.0  # Horizontal radius (X)
@export var height_radius: float = 300.0 # Vertical radius (Y)
@export var speed: float = 0.5           # Speed in radians per second
@export var clockwise: bool = true       # Toggle movement direction

const BEAM = preload("res://levels/miniboss_1/beam.tscn")
const BULLET = preload("res://levels/miniboss_1/bullet.tscn")
const DEBRIS = preload("res://levels/miniboss_1/debris.tscn")

const DEBRIS_TIME = 5.0
const DEBRIS_RATE = 0.5

var attack = ""
var attack_time = 0.0
var debris_cd = 0.0

var FIRE_RATE = 5
var hp = 100
var angle: float = 0.0
var center_position: Vector2

func _ready():
	z_index = 1
	hp = max_hp
	$CanvasLayer/HPBar.max_value = max_hp
	$CanvasLayer/HPBar.value = hp
	$Timer.timeout.connect(fire_beams)
	center_position = position

func _physics_process(delta: float) -> void:
	var direction = 1.0 if clockwise else -1.0
	angle = wrapf(angle + (speed * direction * delta), 0.0, TAU)
	
	run_attacks(delta)
	
	# Calculate the new position along the oval
	var offset_x = cos(angle) * width_radius
	var offset_y = sin(angle) * height_radius
	
	position = center_position + Vector2(offset_x, offset_y)

func take_damage(amount): # free damage after surviving the ultimate
	hp -= amount
	$CanvasLayer/HPBar.value = hp
	if hp<=0:
		queue_free()
		Levels.boss_defeated()

func fire_beams():
	var beam = BEAM.instantiate()
	beam.global_position = position
	get_parent().add_child(beam)
	
	speed = 0
	await get_tree().create_timer(FIRE_RATE).timeout
	speed = 0.5

func run_attacks(delta):
	if attack == "":
		await get_tree().create_timer(FIRE_RATE).timeout
		update_debris(delta)
		return

func view_rect():
	var size = get_viewport_rect().size
	var cam = get_viewport().get_camera_2d()
	if cam:
		size = size / cam.zoom
		return Rect2(cam.get_screen_center_position() - size / 2.0, size)
	return Rect2(Vector2.ZERO, size)

func spawn_debris():
	var view = view_rect()
	var pos = Vector2.ZERO
	match randi() % 4:
		0:
			pos = Vector2(view.position.x - 40.0, randf_range(view.position.y, view.end.y))
		1:
			pos = Vector2(view.end.x + 40.0, randf_range(view.position.y, view.end.y))
		2:
			pos = Vector2(randf_range(view.position.x, view.end.x), view.position.y - 40.0)
		_:
			pos = Vector2(randf_range(view.position.x, view.end.x), view.end.y + 40.0)

	var rock = DEBRIS.instantiate()
	rock.global_position = pos
	rock.target = self
	var to_hole = (global_position - pos).normalized()
	rock.velocity = to_hole.rotated(randf_range(0.5, 1.0) * [-1.0, 1.0].pick_random()) * randf_range(250.0, 350.0)
	get_parent().add_child(rock)

func update_debris(delta):
	if attack_time > DEBRIS_TIME:
		attack=""
		return
	debris_cd -= delta
	if debris_cd <= 0.0:
		debris_cd = DEBRIS_RATE
		for i in range(2):
			spawn_debris()
