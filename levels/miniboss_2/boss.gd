extends Area2D

# Saturn - a single-phase mini boss.
#
# Everything it throws is one of its own rings (see ring_projectile.gd), and
# only ONE attack runs at a time: the boss picks an attack, plays it out, then
# waits a couple of seconds before the next one. Every attack is telegraphed
# with a bright halo, so each is readable and dodgeable.

@export var max_hp: int = 120

const RING = preload("res://levels/miniboss_2/ring_projectile.tscn")

const BODY_RADIUS = 210.0
const SPRITE_SCALE = 1.5
const BAR_SPEED = 120.0

const ATTACKS = ["volley", "orbit", "rain", "split"]
const WINDUP = 0.5
const REST_MIN = 1.6
const REST_MAX = 2.4

# Volley - a fan of rings aimed at the ship
const VOLLEY_COUNT = 5
const VOLLEY_ARC = 42.0          # total fan width, in degrees
const VOLLEY_SPEED = 330.0

# Orbit - rings ring the planet, then all fire outward, leaving one safe gap
const ORBIT_SLOTS = 8            # one slot is left empty as the gap
const ORBIT_RADIUS = 300.0
const ORBIT_TIME = 1.5
const ORBIT_SPEED = 300.0

# Rain - rings drop straight down at the ship's column
const RAIN_COUNT = 5
const RAIN_GAP = 0.55
const RAIN_SPEED = 400.0

# Split - one big ring that bursts into a spread of smaller ones
const SPLIT_SPEED = 320.0
const SPLIT_SHARDS = 8
const SPLIT_DELAY = 0.7
const SPLIT_SHARD_SPEED = 300.0

var hp: int = 0
var spin: float = 0.0
var hit_flash: float = 0.0
var charge: float = 0.0          # telegraph halo
var shake: float = 0.0
var rest: float = 0.0
var attacking: bool = false
var last_attack: String = ""

func _ready() -> void:
	z_index = 1
	add_to_group("boss")
	$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate()
	$CollisionShape2D.shape.radius = BODY_RADIUS
	$Planet.scale = Vector2.ONE * SPRITE_SCALE

	hp = max_hp
	$CanvasLayer/HPBar.max_value = max_hp
	$CanvasLayer/HPBar.value = hp
	body_entered.connect(_on_body_entered)

	rest = 2.0   # a calm opening before the first attack

# ---------- Scheduler (one attack at a time) ----------

func _process(delta: float) -> void:
	spin += delta
	hit_flash = move_toward(hit_flash, 0.0, delta * 4.0)
	charge = move_toward(charge, 0.0, delta * 1.6)
	shake = move_toward(shake, 0.0, delta * 22.0)

	$CanvasLayer/HPBar.value = move_toward($CanvasLayer/HPBar.value, hp, BAR_SPEED * delta)

	# idle animation: slow bob, gentle tilt, a swell while charging
	$Planet.rotation = sin(spin * 0.5) * 0.07
	$Planet.position.y = sin(spin * 1.1) * 12.0
	$Planet.scale = Vector2.ONE * SPRITE_SCALE * (1.0 + 0.05 * charge)
	$Planet.modulate = Color(1, 1, 1).lerp(Color(1.0, 0.55, 0.55), hit_flash)

	var cam := get_viewport().get_camera_2d()
	if cam:
		cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake

	queue_redraw()

	if not attacking:
		rest -= delta
		if rest <= 0.0:
			_start_attack()

func _start_attack() -> void:
	attacking = true
	var pool := ATTACKS.duplicate()
	pool.erase(last_attack)
	var choice: String = pool.pick_random()
	last_attack = choice
	match choice:
		"volley":
			await _attack_volley()
		"orbit":
			await _attack_orbit()
		"rain":
			await _attack_rain()
		"split":
			await _attack_split()
	attacking = false
	rest = randf_range(REST_MIN, REST_MAX)

func _alive() -> bool:
	return is_inside_tree() and hp > 0

func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

# ---------- Attacks ----------

func _attack_volley() -> void:
	charge = 1.0
	await _wait(WINDUP)
	if not _alive():
		return
	var base: float = PI
	var player: Node = get_tree().get_first_node_in_group("player")
	if player:
		base = (player.global_position - global_position).angle()
	for i in range(VOLLEY_COUNT):
		var t: float = 0.0 if VOLLEY_COUNT <= 1 else (float(i) / (VOLLEY_COUNT - 1) - 0.5)
		_spawn_ring(global_position, base + deg_to_rad(t * VOLLEY_ARC), VOLLEY_SPEED, 24.0, Color(1.0, 0.82, 0.42))
	shake = 3.0
	await _wait(0.6)

func _attack_orbit() -> void:
	charge = 1.0
	var gap: int = randi() % ORBIT_SLOTS
	var rings: Array = []
	for i in range(ORBIT_SLOTS):
		if i == gap:
			continue
		var a: float = i * TAU / ORBIT_SLOTS
		var ring: Area2D = _spawn_ring(global_position + Vector2.RIGHT.rotated(a) * ORBIT_RADIUS, a, 0.0, 26.0, Color(1.0, 0.7, 0.45))
		rings.append(ring)
	await _wait(ORBIT_TIME)
	if not _alive():
		return
	for ring in rings:
		if is_instance_valid(ring):
			ring.velocity = (ring.global_position - global_position).normalized() * ORBIT_SPEED
			ring.spin_speed = 6.0
	shake = 4.0
	await _wait(0.8)

func _attack_rain() -> void:
	charge = 1.0
	var view := _view_rect()
	for i in range(RAIN_COUNT):
		if not _alive():
			return
		var x: float = global_position.x
		var player: Node = get_tree().get_first_node_in_group("player")
		if player:
			x = player.global_position.x
		x = clampf(x, view.position.x + 50.0, view.end.x - 50.0)
		var ring: Area2D = _spawn_ring(Vector2(x, view.position.y - 60.0), PI / 2.0, 0.0, 26.0, Color(0.8, 0.85, 1.0))
		ring.velocity = Vector2(0, RAIN_SPEED)
		ring.spin_speed = 5.0
		await _wait(RAIN_GAP)
	await _wait(1.0)

func _attack_split() -> void:
	charge = 1.0
	await _wait(WINDUP * 0.8)
	if not _alive():
		return
	var a: float = PI
	var player: Node = get_tree().get_first_node_in_group("player")
	if player:
		a = (player.global_position - global_position).angle()
	var ring: Area2D = _spawn_ring(global_position, a, SPLIT_SPEED, 44.0, Color(1.0, 0.6, 0.8))
	ring.split_count = SPLIT_SHARDS
	ring.split_delay = SPLIT_DELAY
	ring.split_speed = SPLIT_SHARD_SPEED
	ring.split_radius = 15.0
	await _wait(1.6)

# ---------- Helpers ----------

func _spawn_ring(pos: Vector2, angle: float, speed: float, radius: float, col: Color) -> Area2D:
	var ring: Area2D = RING.instantiate()
	ring.radius = radius
	ring.color = col
	ring.velocity = Vector2.RIGHT.rotated(angle) * speed
	ring.position = pos
	get_parent().add_child(ring)
	return ring

func _view_rect() -> Rect2:
	var size := get_viewport_rect().size
	var cam := get_viewport().get_camera_2d()
	if cam:
		size = size / cam.zoom
		return Rect2(cam.get_screen_center_position() - size / 2.0, size)
	return Rect2(Vector2.ZERO, size)

# ---------- Damage ----------

func take_damage(amount: int) -> void:
	hp -= amount
	hit_flash = 1.0
	if hp <= 0:
		hp = 0
		clear_attacks()
		queue_free()
		Levels.boss_defeated()

func _on_body_entered(body: Node) -> void:
	if body.has_method("die"):
		body.die()

func clear_attacks() -> void:
	for n in get_parent().get_children():
		if n.scene_file_path == "res://levels/miniboss_2/ring_projectile.tscn":
			n.queue_free()

# ---------- Drawing ----------

func _draw() -> void:
	var r := BODY_RADIUS * 1.22
	var glow := 0.10 + 0.55 * charge
	var a := spin * 0.8
	draw_arc(Vector2.ZERO, r, a, a + PI * 1.15, 48, Color(1.0, 0.86, 0.55, glow), 6.0)
	draw_arc(Vector2.ZERO, r, a + PI, a + PI * 2.15, 48, Color(1.0, 0.86, 0.55, glow), 6.0)
	if charge > 0.01:
		draw_circle(Vector2.ZERO, BODY_RADIUS * (0.9 + 0.35 * charge), Color(1.0, 0.9, 0.6, charge * 0.14))
