extends Node
# Autoloaded as "FX". Turns every sprite sheet listed in sheets.json into
# SpriteFrames once, so a regenerated sheet drops straight in.
# Each row of a sheet becomes its own animation: "v0", "v1", ...

const FX_DIR = "res://assets/fx/sun_blackhole_fx/"
const STRIP_SHADER = preload("res://assets/fx/tiled_strip.gdshader")

var frames = {}   # sheet name -> SpriteFrames
var info = {}     # sheet name -> metadata from sheets.json

func _ready():
	var meta = JSON.parse_string(FileAccess.get_file_as_string(FX_DIR + "sheets.json"))
	for m in meta:
		var key = String(m["file"]).get_file().get_basename()
		var tex = load(FX_DIR + m["file"])
		var w = int(m["frame_w"])
		var h = int(m["frame_h"])
		var sf = SpriteFrames.new()
		sf.remove_animation(&"default")
		for row in range(int(m["rows"])):
			var anim = StringName("v%d" % row)
			sf.add_animation(anim)
			sf.set_animation_speed(anim, float(m["fps"]))
			sf.set_animation_loop(anim, bool(m["loop"]))
			for i in range(int(m["frames"])):
				var at = AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(i * w, row * h, w, h)
				sf.add_frame(anim, at)
		m["texture"] = tex
		frames[key] = sf
		info[key] = m

# An animated effect. One-shot sheets free themselves when they finish.
func spawn(key, parent, pos = Vector2.ZERO, variant = 0, px_scale = 1.0):
	var s = AnimatedSprite2D.new()
	s.sprite_frames = frames[key]
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = pos
	s.scale = Vector2.ONE * px_scale
	parent.add_child(s)
	s.play(StringName("v%d" % variant))
	if not bool(info[key]["loop"]):
		s.animation_finished.connect(s.queue_free)
	return s

# A beam-like sheet repeated along `length`, starting at the parent's origin
# and running along +x. Rotate the parent to aim it.
func strip(key, parent, length, px_scale):
	var m = info[key]
	var mat = ShaderMaterial.new()
	mat.shader = STRIP_SHADER
	mat.set_shader_parameter("sheet", m["texture"])
	mat.set_shader_parameter("frames", int(m["frames"]))
	mat.set_shader_parameter("fps", float(m["fps"]))
	mat.set_shader_parameter("tile_px", float(m["frame_w"]) * px_scale)
	mat.set_shader_parameter("rect_w", length)

	var r = ColorRect.new()
	r.material = mat
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.size = Vector2(length, float(m["frame_h"]) * px_scale)
	r.position = Vector2(0, -r.size.y / 2.0)
	parent.add_child(r)
	return r

# Radius (in art pixels) an effect is drawn around, so callers can scale
# it to match a hitbox: scale = hitbox_radius / art_radius(key)
const ART_RADIUS = {
	"sun_ring": 27.0,           # inner edge of the aura
	"sun_fire_ring": 48.0,      # hot core line = damage edge
	"sun_supernova": 30.0,      # the sun disc on frame 0
	"bh_gravity_pull": 76.0,    # where the rings start
	"bh_force_field": 50.0,     # shield rim
	"bh_em_wave_ring": 52.0,
	"bh_ult_ring_loop": 36.0,
	"bh_ult_ring": 62.0,        # final radius of the one-shot
	"bh_spiral_particles": 45.0,
	"bh_random_particles": 45.0,
}

func scale_for(key, radius):
	return radius / ART_RADIUS[key]
