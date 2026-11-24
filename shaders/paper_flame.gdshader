shader_type spatial;
// A tongue of fire (the burning barricades in the Lantern Makers' Rise): a
// flame shape rippling upward, white-gold at its root, orange, deep red at
// its ragged edges, narrowing and breaking up as it rises. Drawn on a flat
// quad; several at different depths and paces make a fire. UV.y: 0 at the
// top of the quad, 1 at its foot. `lean` bends it with the wind (the Fan
// Gust blowing it out); `strength` fades it.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform float speed = 1.6;
uniform float seed = 0.0;
uniform float strength = 1.0;
uniform float lean = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = vec2(UV.x, 1.0 - UV.y);   // y: 0 at its foot, 1 at the top
	float t = TIME * speed + seed * 7.0;
	float n = fbm(vec2(uv.x * 3.2 + seed, uv.y * 2.6 - t * 1.3));
	float m = fbm(vec2(uv.x * 6.0 - seed, uv.y * 5.0 - t * 2.1));
	// The flame's middle sways and leans; it narrows as it rises.
	float middle = 0.5 + (n - 0.5) * 0.4 * uv.y + lean * uv.y * uv.y * 0.45;
	float width = mix(0.3, 0.03, uv.y) + (m - 0.5) * 0.1;
	float d = abs(uv.x - middle);
	float body = smoothstep(width, width * 0.25, d);
	// It breaks up into licks toward the top.
	float top = smoothstep(1.0, 0.35, uv.y + (n - 0.5) * 0.5 + (m - 0.5) * 0.25);
	float foot = smoothstep(0.0, 0.1, uv.y);
	// (Never reaching the quad's sides: cut off there, the fire showed
	// straight edges, a glowing rectangle.)
	float sides = smoothstep(0.0, 0.18, uv.x) * smoothstep(1.0, 0.82, uv.x);
	float flame = clamp(body * top * foot * sides, 0.0, 1.0);
	vec3 col = mix(vec3(0.62, 0.08, 0.03), vec3(1.0, 0.45, 0.1), smoothstep(0.05, 0.45, flame));
	col = mix(col, vec3(1.0, 0.82, 0.45), smoothstep(0.45, 0.8, flame));
	col = mix(col, vec3(1.0, 0.9, 0.62), smoothstep(0.85, 1.0, flame) * (1.0 - uv.y));
	ALBEDO = col * strength;
	ALPHA = flame * strength;
}
