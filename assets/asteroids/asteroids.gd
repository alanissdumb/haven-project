extends Node
# Autoloaded as "Asteroids". Puts a flaming asteroid sprite on a projectile,
# with the rock centred on the node so its hitbox can be a plain circle.
#
# Each PNG has the rock at the lower left and its flame trailing up-right.
# DATA was measured from the art: where the rock sits relative to the image
# centre, the rock's radius (including its yellow outline), and the angle
# the rock leads in.

const DIR = "res://assets/asteroids/asteroid_fire_%02d.png"
const FLICKER = preload("res://assets/fx/flame_flicker.gdshader")

const SMALL = [14, 15, 16, 17, 18, 19, 20, 21]   # the bottom 8
const ALL = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21]

const DATA = {
	1: {"offset": Vector2(-133.3, 100.9), "radius": 87.4, "forward": 2.465},
	2: {"offset": Vector2(-131.2, 94.9), "radius": 65.4, "forward": 2.469},
	3: {"offset": Vector2(-142.9, 92.7), "radius": 62.8, "forward": 2.441},
	4: {"offset": Vector2(-131.8, 95.2), "radius": 64.1, "forward": 2.490},
	5: {"offset": Vector2(-143.3, 93.1), "radius": 61.9, "forward": 2.429},
	6: {"offset": Vector2(-61.9, 49.0), "radius": 33.9, "forward": 2.469},
	7: {"offset": Vector2(-62.8, 57.8), "radius": 35.7, "forward": 2.375},
	8: {"offset": Vector2(-72.5, 62.4), "radius": 45.2, "forward": 2.443},
	9: {"offset": Vector2(-86.6, 68.5), "radius": 48.4, "forward": 2.400},
	10: {"offset": Vector2(-66.8, 52.8), "radius": 39.1, "forward": 2.478},
	11: {"offset": Vector2(-48.3, 39.6), "radius": 32.8, "forward": 2.415},
	12: {"offset": Vector2(-29.5, 23.0), "radius": 22.9, "forward": 2.441},
	13: {"offset": Vector2(-20.7, 15.4), "radius": 16.8, "forward": 2.452},
	14: {"offset": Vector2(-34.3, 22.7), "radius": 16.7, "forward": 2.434},
	15: {"offset": Vector2(-26.2, 22.8), "radius": 17.7, "forward": 2.481},
	16: {"offset": Vector2(-25.4, 24.0), "radius": 18.1, "forward": 2.435},
	17: {"offset": Vector2(-28.0, 23.6), "radius": 21.6, "forward": 2.474},
	18: {"offset": Vector2(-8.7, 7.4), "radius": 9.3, "forward": 2.441},
	19: {"offset": Vector2(-35.8, 26.2), "radius": 22.9, "forward": 2.465},
	20: {"offset": Vector2(-14.4, 11.8), "radius": 11.1, "forward": 2.454},
	21: {"offset": Vector2(-18.7, 11.1), "radius": 16.4, "forward": 2.455},
}

var textures = {}

func _ready():
	for id in ALL:
		textures[id] = load(DIR % id)

# Adds a random asteroid from `pool` to `parent`, scaled so its rock has
# `rock_radius` on screen. Returns the Sprite2D; call aim() as it moves.
func add_sprite(parent, pool, rock_radius):
	var s = make_sprite(parent, pool.pick_random())
	s.scale = Vector2.ONE * rock_radius / art_radius(s)
	return s

# Same, but the rock's size follows the art: the smallest asteroid gets
# `min_radius`, the biggest `max_radius`. Read it back with rock_radius().
func add_sprite_ranged(parent, pool, min_radius, max_radius):
	var s = make_sprite(parent, pool.pick_random())
	var r = remap(art_radius(s), SMALLEST, BIGGEST, min_radius, max_radius)
	s.scale = Vector2.ONE * r / art_radius(s)
	return s

const SMALLEST = 9.3    # art radius of asteroid 18
const BIGGEST = 87.4    # art radius of asteroid 1

func make_sprite(parent, id):
	var s = Sprite2D.new()
	s.texture = textures[id]
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.offset = -DATA[id]["offset"]
	s.set_meta("asteroid_id", id)

	# Flickering fire: everything past the rock (away from where it's heading)
	var d = DATA[id]
	var mat = ShaderMaterial.new()
	mat.shader = FLICKER
	mat.set_shader_parameter("origin", Vector2(s.texture.get_size()) / 2.0 + d["offset"])
	mat.set_shader_parameter("trail", -Vector2.RIGHT.rotated(d["forward"]))
	mat.set_shader_parameter("start", d["radius"])
	mat.set_shader_parameter("wave", 1.0 + d["radius"] * 0.06)
	mat.set_shader_parameter("seed", randf() * 100.0)
	s.material = mat
	parent.add_child(s)
	return s

# On-screen radius of the rock (not the flame): use it for the hitbox.
func rock_radius(sprite):
	return art_radius(sprite) * sprite.scale.x

# Points the rock along `dir` (the flame trails behind). Uses global
# rotation so it ignores any spin on the parent.
func aim(sprite, dir):
	if dir == Vector2.ZERO:
		return
	sprite.global_rotation = dir.angle() - DATA[sprite.get_meta("asteroid_id")]["forward"]

# The rock radius (art px) of one asteroid, for picking sizes by art.
func art_radius(sprite):
	return DATA[sprite.get_meta("asteroid_id")]["radius"]
