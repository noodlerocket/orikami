// The Ronin's paper: his texture, a faint glow of its own, and cloth that
// blows in the wind.
//
// Every point of the model carries two numbers, painted on by
// ronin_puppet.gd when the model loads (they travel in the vertex colour):
//   red   = how far that point can swing. 0 for his body, growing down the
//           length of the cloak, so the hem swings furthest.
//   green = a random-ish number, so neighbouring folds flutter out of step.
//   blue  = 1 on the sculpted sword handle, which slides out of sight while
//           the katana is drawn.
// And CUSTOM0 holds each point's resting position on his body (before the
// skeleton moves it), so his permanent ink marks stay put on the paper as he
// moves, and run on across the seams of his texture.
shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform sampler2D paper : source_color, filter_linear_mipmap;
uniform vec3 glow_color : source_color = vec3(0.92, 0.89, 0.82);
uniform float glow = 0.2;

// Which way the air pushes the cloth, in the model's own space. A length of
// 1 means "as strong as gravity": the cloak then streams out at 45 degrees.
uniform vec3 push = vec3(0.0);
uniform float flutter_clock = 0.0;
uniform float flutter = 0.22;
// Converts the painted swing distance into the model's units.
uniform float reach_scale = 1.2;
// How far the sculpted sword handle moves when the katana is drawn.
uniform vec3 hilt_slide = vec3(0.0);
// How much ink is on him: 1 = soaked black (the instant he is struck),
// 0 = clean. As it falls, the blots shrink away.
uniform float ink = 0.0;
uniform vec3 ink_color : source_color = vec3(0.07, 0.07, 0.1);
// His permanent ink marks: 0 = blank, 1 = covered in dense calligraphy. They
// grow from faint thin strokes in a few places to bold strokes everywhere.
uniform float marks = 0.0;
uniform vec3 mark_color : source_color = vec3(0.1, 0.1, 0.14);

varying vec3 body;

// Soft random blotches, used for the shape of the ink stains.
float speck(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float blotch(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(speck(cell), speck(cell + vec2(1.0, 0.0)), f.x),
			mix(speck(cell + vec2(0.0, 1.0)), speck(cell + vec2(1.0, 1.0)), f.x), f.y);
}

// The same soft noise in three dimensions, on his body.
float speck3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise3(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(speck3(cell), speck3(cell + vec3(1, 0, 0)), f.x),
			mix(speck3(cell + vec3(0, 1, 0)), speck3(cell + vec3(1, 1, 0)), f.x), f.y);
	float b = mix(mix(speck3(cell + vec3(0, 0, 1)), speck3(cell + vec3(1, 0, 1)), f.x),
			mix(speck3(cell + vec3(0, 1, 1)), speck3(cell + vec3(1, 1, 1)), f.x), f.y);
	return mix(a, b, f.z);
}

// How much ink is drawn at this point of his body, for a given amount of marks.
float ink_marks(vec3 p, float amount) {
	if (amount <= 0.001) {
		return 0.0;
	}
	// Where the marks have reached: broad patches that open up as the
	// amount grows, so the first strokes appear in a few places only.
	float reach = noise3(p * 2.6 + vec3(4.0, 9.0, 1.0)) * 0.75 + noise3(p * 6.0) * 0.25;
	float here = 1.0 - smoothstep(amount * 1.1 + 0.08, amount * 1.1 + 0.16, reach);
	// The strokes: thin lines that follow the curves of a stretched noise
	// field, so they flow down and across him like brushwork.
	vec3 q = vec3(p.x * 6.0 + p.y * 1.5, p.y * 2.4, p.z * 6.0 - p.y * 1.0);
	float wave = noise3(q) * 0.7 + noise3(q * 2.3 + 7.0) * 0.3;
	float width = mix(0.012, 0.03, amount);
	// Each stroke swells and thins along its length, like a brush pressed
	// and lifted (never to a blob).
	width *= 0.55 + 0.7 * noise3(p * 9.0 + 3.0);
	float stroke = 1.0 - smoothstep(width * 0.55, width, abs(wave - 0.5));
	// Heavily inked: soaked patches join the strokes.
	float soak = (1.0 - smoothstep(0.2, 0.24, noise3(p * 7.0 + 11.0))) * smoothstep(0.7, 1.0, amount);
	return max(stroke, soak) * here;
}

void vertex() {
	body = CUSTOM0.xyz;
	float reach = COLOR.r * reach_scale;
	if (reach > 0.0) {
		float wave = sin(flutter_clock * 4.2 + COLOR.g * 30.0) + 0.4 * sin(flutter_clock * 7.0 + COLOR.g * 17.0);
		vec3 pull = push * (1.0 + wave * flutter);
		pull.x += wave * flutter * 0.5 * length(push);
		// Cloth hangs along "gravity plus wind". Swing this point from
		// hanging straight down to hanging along that line.
		vec3 hang = normalize(vec3(0.0, -1.0, 0.0) + pull);
		VERTEX += reach * (hang + vec3(0.0, 1.0, 0.0));
	}
	VERTEX += hilt_slide * COLOR.b;
}

void fragment() {
	vec3 tint = texture(paper, UV).rgb;
	// Ink soaks in wherever the blotch pattern is below the ink level.
	float pattern = blotch(UV * 9.0) * 0.65 + blotch(UV * 27.0) * 0.35;
	float stain = (1.0 - smoothstep(ink - 0.08, ink + 0.02, pattern)) * step(0.001, ink);
	float marked = ink_marks(body, marks) * 0.92;
	vec3 inked = mix(tint, mark_color, marked);
	ALBEDO = mix(inked, ink_color, stain);
	ROUGHNESS = 1.0;
	EMISSION = tint * glow_color * glow * (1.0 - stain) * (1.0 - marked);
}
