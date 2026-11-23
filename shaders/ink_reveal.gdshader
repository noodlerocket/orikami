shader_type canvas_item;
// An ink painting laid over a sheet of paper (multiplied, so only its ink
// shows), appearing as if brushed and soaking in, then wiped away.
// `painted` 0 to 1: the ink spreads in from the upper left in soft, blotchy
// tongues, the darkest ink first; `wiped` 0 to 1: a damp cloth sweeps it
// away from the left. Used by the Paper-Maker's tale.
render_mode blend_mul, unshaded;

uniform float painted = 1.0;
uniform float wiped = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	return 0.55 * vnoise(p) + 0.3 * vnoise(p * 2.3) + 0.15 * vnoise(p * 5.1);
}

void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	float dark = 1.0 - dot(ink.rgb, vec3(0.33, 0.34, 0.33));
	float n = fbm(UV * vec2(5.0, 3.5));
	// Where the spreading front has reached: along a diagonal, broken up by
	// noise; dark ink reaches a little ahead of the pale washes.
	float along = UV.x * 0.62 + UV.y * 0.38 + (n - 0.5) * 0.4 - dark * 0.12;
	float front = painted * 1.5 - 0.2;
	float shown = 1.0 - smoothstep(front - 0.16, front, along);
	// The wipe, from the left, ragged.
	float sweep = wiped * 1.35 - 0.15;
	float gone = 1.0 - smoothstep(sweep - 0.1, sweep, UV.x + (n - 0.5) * 0.22);
	float k = shown * (1.0 - gone);
	COLOR = vec4(mix(vec3(1.0), ink.rgb, k), 1.0);
}
