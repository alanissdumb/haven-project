// Repeats one animated frame of a horizontal sheet along a ColorRect.
// Used for beams (see FX.strip()).
shader_type canvas_item;

uniform sampler2D sheet : filter_nearest, repeat_disable;
uniform int frames = 8;
uniform float fps = 14.0;
uniform float tile_px = 64.0;   // on-screen width of one tile = frame_w * scale
uniform float rect_w = 512.0;   // ColorRect width (the beam length)

void fragment() {
	float f = floor(mod(TIME * fps, float(frames)));
	float u = clamp(fract(UV.x * rect_w / tile_px), 0.001, 0.999);
	COLOR = texture(sheet, vec2((f + u) / float(frames), UV.y)) * COLOR;
}
