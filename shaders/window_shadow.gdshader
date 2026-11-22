shader_type spatial;
// A villager's shadow cast on a lit shoji from inside (VillagerShadow): a
// soft dark warm shape, cut off at the edges of the window it is on, so it
// can move about and slip out of sight at the edge.
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;

uniform vec4 tint : source_color = vec4(0.22, 0.11, 0.05, 0.6);
uniform vec4 window_rect = vec4(0.0, 0.0, 1.0, 1.0);  // world x, y of its lower left corner, and its width, height
uniform float round_window = 0.0;  // 1 = a round window (the rect's inscribed circle)
uniform float fade = 1.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = (world_pos.xy - window_rect.xy) / window_rect.zw;
	if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0) {
		discard;
	}
	if (round_window > 0.5 && length(p - vec2(0.5)) > 0.5) {
		discard;
	}
	// A little softer toward the window's edges, like light spreading.
	float edge = smoothstep(0.0, 0.08, min(min(p.x, 1.0 - p.x), min(p.y, 1.0 - p.y)));
	ALBEDO = tint.rgb;
	ALPHA = tint.a * fade * (0.6 + 0.4 * edge);
}
