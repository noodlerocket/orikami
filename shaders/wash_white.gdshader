// Laid over the Hannya's own paper at her end (HannyaEnding): her mask is
// washed blank, the white spreading out from the middle of her face with a
// soft, ragged edge, like paper soaking through. Nothing else of her changes.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, fog_disabled;

uniform vec3 centre = vec3(0.0);
uniform float radius = 0.26;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 paper : source_color = vec4(0.92, 0.91, 0.88, 1.0);

varying vec3 world_pos;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float d = distance(world_pos, centre);
	// The edge creeps outward as `amount` grows, a little ragged.
	float reach = radius * amount + (hash(floor(world_pos * 40.0)) - 0.5) * 0.02;
	float a = 1.0 - smoothstep(reach * 0.75, reach, d);
	ALBEDO = paper.rgb;
	ALPHA = a * paper.a * step(0.001, amount);
}
