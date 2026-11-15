// Makes the flame part of a sprite flicker, pixel-art style.
// Everything closer than `start` to `origin` (along `trail`) is left alone,
// so the ship body / the rock never moves. Past that, the flame stretches
// and shrinks and its edges wave, in choppy steps so it stays pixel-crisp.
// All distances are in texture pixels.
shader_type canvas_item;

uniform vec2 origin = vec2(0.0);        // where the flame starts (texture px)
uniform vec2 trail = vec2(0.0, 1.0);    // direction the flame points (normalized)
uniform float start = 0.0;              // leave this much past `origin` untouched
uniform float half_width = 10000.0;     // only touch pixels this close to the trail line
uniform float stretch = 0.18;           // how much the flame length flickers (0.18 = +/-18%)
uniform float wave = 2.0;               // sideways wobble at the tip (texture px)
uniform float fps = 12.0;               // flicker steps per second
uniform float seed = 0.0;               // per-sprite offset so they don't flicker in sync

float hash(float n) {
	return fract(sin(n * 12.9898 + seed * 78.233) * 43758.5453);
}

void fragment() {
	vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 p = UV * tex_size;
	vec2 rel = p - origin;
	float along = dot(rel, trail);
	float across = dot(rel, vec2(-trail.y, trail.x));

	if (along > start && abs(across) < half_width) {
		float step_t = floor(TIME * fps + seed * 7.0);
		float k = 1.0 + stretch * (hash(step_t) * 2.0 - 1.0);   // length this step
		float f = along - start;
		float tip = clamp(f / 40.0, 0.0, 1.0);                    // wobble grows toward the tip
		float w = floor(sin(f * 0.35 - step_t * 1.7) * wave * tip + 0.5);
		vec2 q = origin + trail * (start + f / k) + vec2(-trail.y, trail.x) * (across + w);
		q = floor(q) + 0.5;                                       // stay on the pixel grid
		COLOR = texture(TEXTURE, q / tex_size) * COLOR;
	} else {
		COLOR = texture(TEXTURE, UV) * COLOR;
	}
}
