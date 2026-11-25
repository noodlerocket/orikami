shader_type spatial;
// A curtain of ink pouring (Sumi Marsh: off the broken aqueduct, out of
// broken gutters): dark glossy streaks running down at slightly different
// speeds, every frame, each catching a thin pale glint of the fog, softer at
// its sides, a dark froth where it lands. UV.y runs from the lip (0) to the
// ink below (1).
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.03, 0.03, 0.05, 0.92);
uniform vec4 glint : source_color = vec4(0.55, 0.62, 0.62, 1.0);
uniform float speed = 1.8;
uniform float columns = 16.0;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void fragment() {
	float col = floor(UV.x * columns);
	float off = hash(col) * 7.0;
	float sp = speed * (0.75 + 0.5 * hash(col + 3.1));
	float v = fract(UV.y * 2.0 - TIME * sp + off);
	float streak = smoothstep(0.0, 0.35, v) * smoothstep(1.0, 0.6, v);
	// A thin bright line down the middle of some streaks: the sheen on ink.
	float across = fract(UV.x * columns);
	float line = smoothstep(0.35, 0.5, across) * smoothstep(0.65, 0.5, across) * step(0.55, hash(col + 9.7));
	float edge = smoothstep(0.0, 0.2, UV.x) * smoothstep(1.0, 0.8, UV.x);
	float a = (0.6 + 0.35 * streak) * edge;
	float froth = smoothstep(0.85, 1.0, UV.y);
	a = max(a, froth * 0.8 * edge);
	a *= smoothstep(0.0, 0.04, UV.y);
	vec3 c = mix(tint.rgb, glint.rgb, clamp(line * streak * 0.6 + streak * 0.08, 0.0, 1.0));
	c = mix(c, vec3(0.16, 0.17, 0.19), froth * 0.6);
	ALBEDO = c;
	ALPHA = clamp(a, 0.0, 1.0) * tint.a;
}
