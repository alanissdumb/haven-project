extends Area2D

# One of Saturn's rings, thrown at the ship. It spins, pops in with a little
# scale animation, and it can burst apart into a spread of smaller rings
# (that is the "Split" attack).
#
# Properties are set by the boss before the ring is added to the scene.

const SHARD_SCENE = "res://levels/miniboss_2/ring_projectile.tscn"

var velocity: Vector2 = Vector2.ZERO
var radius: float = 26.0
var color: Color = Color(1.0, 0.82, 0.42)
var spin_speed: float = 3.2
var lifetime: float = 8.0
var age: float = 0.0

# Split behaviour (split_count = 0 means it never splits)
var split_count: int = 0
var split_delay: float = 0.0
var split_speed: float = 320.0
var split_radius: float = 15.0
var split_done: bool = false

func _ready() -> void:
	z_index = 2
	scale = Vector2.ZERO   # pop in
	var cs: CollisionShape2D = $CollisionShape2D
	cs.shape = cs.shape.duplicate()
	cs.shape.radius = maxf(7.0, radius * 0.85)

func _physics_process(delta: float) -> void:
	age += delta
	rotation += spin_speed * delta
	if scale.x < 1.0:
		scale = Vector2.ONE * minf(1.0, scale.x + delta * 7.0)

	position += velocity * delta

	if age > lifetime:
		queue_free()
		return

	if split_count > 0 and not split_done and age >= split_delay:
		_do_split()
		return

	for body in get_overlapping_bodies():
		if body.has_method("can_be_hit") and body.can_be_hit():
			body.take_damage(1)
			queue_free()
			return

func _do_split() -> void:
	split_done = true
	var parent: Node = get_parent()
	if parent == null:
		queue_free()
		return
	var scene: PackedScene = load(SHARD_SCENE)
	for i in range(split_count):
		var shard: Area2D = scene.instantiate()
		shard.radius = split_radius
		shard.color = color
		shard.spin_speed = 6.0
		shard.velocity = Vector2.RIGHT.rotated(i * TAU / split_count + rotation) * split_speed
		shard.position = global_position
		parent.add_child(shard)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius * 1.6, Color(color, 0.10))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 40, Color(color, 0.95), maxf(4.0, radius * 0.34))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 40, Color(1.0, 1.0, 1.0, 0.9), maxf(1.5, radius * 0.11))
	draw_circle(Vector2.ZERO, radius * 0.26, Color(1.0, 0.95, 0.82))