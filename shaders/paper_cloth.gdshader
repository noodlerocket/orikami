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

void vertex() {
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
	ALBEDO = mix(tint, ink_color, stain);
	ROUGHNESS = 1.0;
	EMISSION = tint * glow_color * glow * (1.0 - stain);
}
