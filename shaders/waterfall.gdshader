shader_type spatial;
// A sheet of falling water (the Falls in the Bamboo of Folded Wind): pale
// streaks running down at slightly different speeds, every frame, softer at
// its sides, white water where it meets the pool. UV.y runs from the top (0)
// to the pool (1).
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.58, 0.72, 0.78, 0.95);
uniform float speed = 1.6;
uniform float columns = 22.0;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void fragment() {
	float col = floor(UV.x * columns);
	float off = hash(col) * 7.0;
	float sp = speed * (0.75 + 0.5 * hash(col + 3.1));
	float v = fract(UV.y * 2.5 - TIME * sp + off);
	float streak = smoothstep(0.0, 0.4, v) * smoothstep(1.0, 0.55, v);
	float edge = smoothstep(0.0, 0.18, UV.x) * smoothstep(1.0, 0.82, UV.x);
	float a = (0.55 + 0.4 * streak) * edge;
	float foam = smoothstep(0.82, 1.0, UV.y);
	a = max(a, foam * 0.85 * edge);
	// Thinner where it leaves the lip.
	a *= smoothstep(0.0, 0.05, UV.y);
	ALBEDO = mix(tint.rgb, vec3(0.95, 0.97, 0.98), clamp(streak * 0.7 + foam, 0.0, 1.0));
	ALPHA = clamp(a, 0.0, 1.0) * tint.a;
}
