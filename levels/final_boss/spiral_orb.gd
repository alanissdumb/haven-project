extends Area2D
const RADIUS = 14.0
const LIFETIME = 7.0
const PX_SCALE = 3.0      # medium blob is ~5 art px -> about RADIUS on screen

var sheet = "bh_matter_dots"   # or "bh_void_orbs"; set by the boss
var variant = 1                # 0/1/2 = small/medium/large
var color = Color.WHITE        # tint; minions shoot pink ones

var velocity = Vector2.ZERO
var age = 0.0

func _ready():
	FX.spawn(sheet, self, Vector2.ZERO, variant, PX_SCALE).modulate = color

func _physics_process(delta):
	position += velocity * delta
	age += delta
	if age > LIFETIME:
		queue_free()
		return

	for body in get_overlapping_bodies():
		if body.has_method("can_be_hit") and body.can_be_hit():
			body.take_damage(1)
			queue_free()
			return
