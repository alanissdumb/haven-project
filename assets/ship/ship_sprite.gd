extends Sprite2D
# The player's ship. The player script sets `thrust` every frame and the
# sprite swaps to the matching engine flame.
# `engine` is the flame colour; an engine upgrade will switch it to "blue".

enum { THRUST_OFF, THRUST_SMALL, THRUST_BIG }

const TEXTURES = {
	"off": preload("res://assets/ship/ship_idle.png"),
	"orange": [preload("res://assets/ship/ship_orange_small.png"), preload("res://assets/ship/ship_orange_big.png")],
	"blue": [preload("res://assets/ship/ship_blue_small.png"), preload("res://assets/ship/ship_blue_big.png")],
}

@export_enum("orange", "blue") var engine = "orange"

# Where the flames come out, in ship_*.png pixels (nose up, flames below)
const NOZZLE = Vector2(109, 388)
const FLAME_HALF_WIDTH = 34.0
const FLICKER = preload("res://assets/fx/flame_flicker.gdshader")

var thrust = THRUST_OFF:
	set(value):
		thrust = value
		update_texture()

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat = ShaderMaterial.new()
	mat.shader = FLICKER
	mat.set_shader_parameter("origin", NOZZLE)
	mat.set_shader_parameter("trail", Vector2.DOWN)
	mat.set_shader_parameter("half_width", FLAME_HALF_WIDTH)
	mat.set_shader_parameter("wave", 2.0)
	mat.set_shader_parameter("fps", 16.0)
	mat.set_shader_parameter("seed", randf() * 100.0)
	material = mat
	update_texture()

func update_texture():
	if thrust == THRUST_OFF:
		texture = TEXTURES["off"]
	else:
		texture = TEXTURES[engine][thrust - 1]
