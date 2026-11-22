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
// Struck by fire: his paper is scorched round burn_at (a point on his resting
// body, like `body`). burn_reach = how far the scorch has spread, in metres
// (0 = none): a black char in the middle, a glowing ember line along its
// edge (burn_glow = how bright it still is), brown scorch round that.
uniform vec3 burn_at = vec3(0.0, 1.0, 0.1);
uniform float burn_reach = 0.0;
uniform float burn_glow = 0.0;
uniform vec3 char_color : source_color = vec3(0.075, 0.05, 0.035);
uniform vec3 scorch_color : source_color = vec3(0.46, 0.3, 0.16);
uniform vec3 ember_color : source_color = vec3(1.0, 0.42, 0.1);
// Struck by a blade, claws or teeth: a slit torn across him through tear_at,
// along the plane whose normal is tear_normal. tear = how open it is (1 just
// torn, 0 closed); tear_length = how long it is, in metres.
uniform vec3 tear_at = vec3(0.0, 1.0, 0.1);
uniform vec3 tear_normal = vec3(0.0, 0.7, 0.7);
uniform float tear = 0.0;
uniform float tear_length = 0.0;
uniform vec3 tear_gap_color : source_color = vec3(0.12, 0.12, 0.16);
uniform vec3 tear_shadow_color : source_color = vec3(0.42, 0.41, 0.46);
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
	vec3 colour = mix(inked, ink_color, stain);
	float lit = (1.0 - stain) * (1.0 - marked);
	vec3 shine = vec3(0.0);

	// Scorched: a ragged edge (two sizes of noise), char inside, the ember
	// line on the char's edge, brown scorch fading out beyond it.
	if (burn_reach > 0.001) {
		float d = distance(body, burn_at) + (noise3(body * 13.0) - 0.5) * 0.09
				+ (noise3(body * 37.0 + 5.0) - 0.5) * 0.035;
		float core = burn_reach * 0.62;
		float charred = 1.0 - smoothstep(core - 0.012, core + 0.004, d);
		float scorched = (1.0 - smoothstep(core, burn_reach, d)) * (1.0 - charred);
		float rim = (1.0 - smoothstep(0.0, 0.016, abs(d - core))) * burn_glow;
		// A few sparks still smouldering in the char.
		float sparks = smoothstep(0.74, 0.8, noise3(body * 48.0)) * charred * burn_glow * 0.7;
		colour = mix(colour, scorch_color, scorched * 0.85);
		colour = mix(colour, char_color, charred);
		lit *= 1.0 - max(charred, scorched * 0.7);
		shine += ember_color * (rim * 1.6 + sparks * 1.2);
		colour = mix(colour, ember_color, rim * 0.8);
	}

	// Torn: a narrow dark gap through the paper with pale ragged fibres on
	// both lips, and a soft crease shadow below it where the paper buckles.
	if (tear > 0.001 && tear_length > 0.001) {
		vec3 n = normalize(tear_normal);
		vec3 rel = body - tear_at;
		float across = dot(rel, n) + (noise3(body * 60.0) - 0.5) * 0.01;
		float along = length(rel - n * dot(rel, n));
		// Pointed at both ends, like a slit.
		float taper = 1.0 - smoothstep(tear_length * 0.3, tear_length * 0.5, along);
		float w = 0.022 * tear * taper;
		if (w > 0.0005) {
			float gap = 1.0 - smoothstep(w * 0.45, w * 0.8, abs(across));
			float lips = (1.0 - smoothstep(w * 0.8, w * 1.9 + 0.003, abs(across))) * (1.0 - gap);
			float crease = (1.0 - smoothstep(w, w + 0.07 * tear * taper, -across)) * step(across, 0.0) * (1.0 - gap - lips);
			colour = mix(colour, tear_shadow_color, crease * 0.8);
			colour = mix(colour, vec3(1.0, 0.99, 0.96), lips);
			colour = mix(colour, tear_gap_color, gap);
			lit *= 1.0 - max(gap, crease * 0.5);
			shine += vec3(1.0, 0.99, 0.95) * lips * 0.35;
		}
	}

	ALBEDO = colour;
	ROUGHNESS = 1.0;
	EMISSION = tint * glow_color * glow * lit + shine;
}
