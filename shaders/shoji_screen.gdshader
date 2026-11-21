// The shoji screen of the Hannya's shrine: paper lit from behind by a lamp,
// with her shadow on it.
//
// `shadow` is a picture of her silhouette (white on black) taken by a camera
// standing where the lamp is (hannya_stage.gd). It is blurred here, more or
// less (`softness`), so the shadow is soft like a real one on paper.
//
// The screen can also:
//   - bleed ink (`ink` 0 to 1): black blooms that spread outward from her
//     shadow through the fibres of the paper;
//   - be slashed (`slash_a`, `slash_b`: two cuts, from one end to the other
//     in UV; `slash_open` how far each has been torn open, 0 to 1);
//   - be torn open (`tear`): a ragged hole around `tear_center`.
// Torn edges get a pale rim, like every torn sheet in the game.
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

uniform sampler2D shadow : hint_default_black, filter_linear;
// The shape the ink bleeds from: her shadow while she is behind the paper,
// then a frozen copy of it once she has come out (so the stain stays).
uniform sampler2D ink_shape : hint_default_black, filter_linear;
uniform float softness = 0.006;
uniform float shadow_strength = 0.92;
uniform vec3 glow_color : source_color = vec3(1.0, 0.72, 0.42);
uniform float glow_energy = 1.05;
// Where the lamp is, seen through the paper (UV): the paper is brightest there.
uniform vec2 lamp_uv = vec2(0.5, 0.9);
// 1 = lit, 0 = the lamp is out.
uniform float light = 1.0;
uniform vec3 paper_dark : source_color = vec3(0.09, 0.08, 0.11);
uniform vec3 rim_color : source_color = vec3(0.86, 0.82, 0.74);
uniform float ink = 0.0;
uniform vec3 ink_color : source_color = vec3(0.04, 0.03, 0.05);
uniform vec4 slash_a = vec4(0.25, 0.85, 0.7, 0.2);
uniform vec4 slash_b = vec4(0.75, 0.9, 0.3, 0.25);
uniform vec2 slash_open = vec2(0.0);
uniform float tear = 0.0;
uniform vec2 tear_center = vec2(0.5, 0.62);
// The screen's width over its height, so round things stay round.
uniform float aspect = 1.24;
uniform float flicker = 0.0;

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

float fibres(vec2 p) {
	return noise(p * 40.0) * 0.5 + noise(p * 110.0) * 0.3 + noise(p * 9.0) * 0.2;
}

// A silhouette picture, blurred over 13 samples in two rings.
float soft(sampler2D pic, vec2 uv, float radius) {
	float sum = texture(pic, uv).r * 2.0;
	for (int i = 0; i < 6; i++) {
		float a = float(i) * 1.0472;
		vec2 d = vec2(cos(a), sin(a) * aspect);
		sum += texture(pic, uv + d * radius * 0.5).r;
		sum += texture(pic, uv + d.yx * vec2(-1.0, 1.0) * radius).r;
	}
	return sum / 14.0;
}

// How far `p` is from the cut that runs from `s.xy` to `s.zw`, and how wide
// that cut is torn open there (widest in the middle, closed at the ends).
float slit(vec2 p, vec4 s, float open) {
	if (open <= 0.0) {
		return 1.0;  // not cut yet: no hole, no rim
	}
	vec2 a = s.xy;
	vec2 b = s.zw;
	vec2 pa = (p - a) * vec2(aspect, 1.0);
	vec2 ba = (b - a) * vec2(aspect, 1.0);
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	float d = length(pa - ba * h);
	float width = open * 0.05 * sin(3.14159 * h) * (0.7 + 0.6 * noise(p * 30.0));
	return d - width;  // below 0 = inside the cut
}

void fragment() {
	vec2 uv = UV;
	// The shadow camera looks the other way, so its picture is mirrored.
	vec2 suv = vec2(1.0 - uv.x, uv.y);
	float her = soft(shadow, suv, softness);

	// Holes: the two slashes and the torn-open middle.
	float hole_edge = 1.0;
	hole_edge = min(hole_edge, slit(uv, slash_a, slash_open.x));
	hole_edge = min(hole_edge, slit(uv, slash_b, slash_open.y));
	vec2 from_tear = (uv - tear_center) * vec2(aspect, 1.0);
	float ragged = 0.75 + 0.5 * noise(normalize(from_tear + 0.0001) * 4.0 + 3.0) + 0.25 * noise(uv * 25.0);
	hole_edge = min(hole_edge, length(from_tear) - tear * 0.34 * ragged);
	if (hole_edge < 0.0) {
		discard;
	}
	float rim = 1.0 - smoothstep(0.0, 0.012, hole_edge);

	// Ink bleeding out from her shadow: a wide blur of the shadow, broken up
	// by the fibres, crosses a rising threshold.
	float near_her = soft(ink_shape, suv, 0.06) * 0.6 + soft(ink_shape, suv, 0.15) * 0.4;
	// (Mostly her shape, so it blooms out from her; a little noise for a
	// ragged, feathered edge, not scattered blotches.)
	float bleed = near_her * 1.5 + noise(uv * 7.0) * 0.12 + fibres(uv * 1.3) * 0.08;
	float inked = smoothstep(1.4 - ink * 1.3, 1.48 - ink * 1.3, bleed) * step(0.001, ink);

	float paper = 0.82 + 0.3 * fibres(uv);
	vec2 from_lamp = (uv - lamp_uv) * vec2(aspect, 1.0);
	float pool = 0.5 + 0.75 * exp(-dot(from_lamp, from_lamp) * 2.2);
	float lit = light * pool * (1.0 - her * shadow_strength) * (1.0 - flicker * 0.25 * noise(vec2(TIME * 9.0, 0.0)));
	vec3 glow = glow_color * glow_energy * paper * lit;
	vec3 colour = paper_dark * paper + glow;
	colour = mix(colour, ink_color, inked * 0.94);
	colour = mix(colour, rim_color * (0.35 + 0.65 * light), rim);
	ALBEDO = colour;
}
