extends Area2D

# One of Saturn's projectiles, thrown at the ship: a flaming asteroid (one of
# the small ones). It pops in with a little scale animation, and it can burst
# apart into a spread of smaller ones (that is the "Split" attack).
#
# Properties are set by the boss before the ring is added to the scene.

const SHARD_SCENE = "res://levels/miniboss_2/ring_projectile.tscn"

var velocity: Vector2 = Vector2.ZERO
var heading: float = 0.0   # which way the rock points while it isn't moving yet
var radius: float = 26.0
var color: Color = Color(1.0, 0.82, 0.42)   # set by the boss per attack; not drawn any more
var spin_speed: float = 3.2
var lifetime: float = 8.0
var age: float = 0.0

# Split behaviour (split_count = 0 means it never splits)
var split_count: int = 0
var split_delay: float = 0.0
var split_speed: float = 320.0
var split_radius: float = 15.0
var split_done: bool = false

const HITBOX = 0.9   # hitbox radius, as a fraction of the rock
var art: Sprite2D = null

func _ready() -> void:
	z_index = 2
	scale = Vector2.ZERO   # pop in
	var cs: CollisionShape2D = $CollisionShape2D
	cs.shape = cs.shape.duplicate()
	art = Asteroids.add_sprite(self, Asteroids.SMALL, radius)
	_aim()
	cs.shape.radius = maxf(7.0, radius * HITBOX)

func _physics_process(delta: float) -> void:
	age += delta
	rotation += spin_speed * delta
	if scale.x < 1.0:
		scale = Vector2.ONE * minf(1.0, scale.x + delta * 7.0)

	position += velocity * delta
	_aim()

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

# The node spins (shards use its rotation), but the rock always flies rock-first
func _aim() -> void:
	var dir: Vector2 = velocity if velocity != Vector2.ZERO else Vector2.RIGHT.rotated(heading)
	Asteroids.aim(art, dir)

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
