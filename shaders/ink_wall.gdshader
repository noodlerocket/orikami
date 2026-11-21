// The wall of ink that seals the Hannya's courtyard: a sheet of black ink
// rising out of a pool. Solid and glossy at the foot, thinning and breaking
// into streaks toward its ragged top, and always running downward.
//
// `rise` (0 to 1) is how far it has risen out of the pool; setting it back
// to 0 sinks it again.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;

uniform float rise = 0.0;
uniform vec3 ink : source_color = vec3(0.015, 0.015, 0.035);
uniform vec3 sheen : source_color = vec3(0.3, 0.32, 0.45);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float up = 1.0 - UV.y;           // 0 at the foot, 1 at the top
	float across = UV.x;
	// Streaks of ink running down: stretched noise scrolling downward.
	float run = noise(vec2(across * 9.0, up * 1.5 + TIME * 1.6)) * 0.6
			+ noise(vec2(across * 23.0, up * 3.0 + TIME * 2.7)) * 0.4;
	// The ragged top: higher in some streaks than others.
	float top = rise * (0.55 + 0.45 * noise(vec2(across * 6.0, TIME * 0.3)));
	float body = 1.0 - smoothstep(top - 0.25, top, up);
	// Thick at the foot, breaking into streaks higher up.
	float streaky = mix(1.0, smoothstep(0.35, 0.6, run), smoothstep(0.1, 0.7, up));
	// Softer at its left and right edges.
	float sides = smoothstep(0.0, 0.22, across) * smoothstep(1.0, 0.78, across);
	float alpha = body * streaky * sides;
	if (alpha < 0.02) {
		discard;
	}
	// A wet sheen running down it.
	float shine = smoothstep(0.7, 0.95, noise(vec2(across * 4.0, up * 2.0 + TIME * 2.0)));
	ALBEDO = mix(ink, sheen, shine * 0.35);
	ALPHA = alpha * 0.96;
}
