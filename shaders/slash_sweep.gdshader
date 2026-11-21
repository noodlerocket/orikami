// The white swoosh of a sword cut.
//
// The swoosh is one curved strip of paper. Only the part between `tail` and
// `head` is shown (both run from 0 at the end where the cut starts to 1 at
// the end where it finishes):
//   - first `head` races along the strip, so the swoosh is drawn on in the
//     direction the sword travels;
//   - then `tail` follows it, so the swoosh is wiped away from the same end
//     it started at, instead of vanishing all at once.
// ronin_puppet.gd moves the two numbers.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never, fog_disabled;

uniform float head = 0.0;
uniform float tail = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.95);

void fragment() {
	float along = UV.x;   // 0 = where the cut starts, 1 = where it ends
	float across = UV.y;  // 0 = inner edge, 1 = outer (leading) edge
	// Crisp at the head, soft where the tail is eating it away.
	float shown = smoothstep(tail, tail + 0.12, along) * (1.0 - smoothstep(head - 0.03, head, along));
	// Solid along the outer edge, thinning toward the inside, like a brush
	// stroke pressed hardest on one side.
	float body = mix(0.35, 1.0, smoothstep(0.0, 0.6, across));
	ALBEDO = tint.rgb;
	ALPHA = shown * body * tint.a;
}
