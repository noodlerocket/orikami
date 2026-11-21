// Paper-grain overlay. Drawn over the whole screen and MULTIPLIED with the
// picture underneath, so everything looks printed on slightly rough washi.
// All the knobs below show up in the Inspector under the material.
shader_type canvas_item;
render_mode blend_mul;

uniform float grain_strength : hint_range(0.0, 0.6) = 0.2;
uniform float fiber_strength : hint_range(0.0, 0.6) = 0.14;
uniform float blotch_strength : hint_range(0.0, 0.6) = 0.1;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.4;
uniform float grain_scale = 380.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Smooth random noise.
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	// Correct for the screen's shape so the grain isn't stretched.
	vec2 p = UV * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float fine = noise(p * grain_scale);
	// Long, slightly wavy horizontal fibres.
	float fibers = noise(vec2(p.x * 30.0 + noise(p * 5.0) * 4.0, p.y * 520.0));
	float blotch = noise(p * 5.0);
	float value = 1.0
			+ (fine - 0.5) * grain_strength
			+ (fibers - 0.5) * fiber_strength
			+ (blotch - 0.5) * blotch_strength;
	// Darken the corners a little.
	float edge = smoothstep(0.45, 1.0, length(UV - 0.5) * 1.35);
	value *= 1.0 - edge * vignette_strength;
	COLOR = vec4(vec3(value), 1.0);
}
