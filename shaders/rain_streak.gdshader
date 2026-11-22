shader_type spatial;
// A raindrop streak (Rain). Turned to face the camera about the vertical only
// (like BILLBOARD_FIXED_Y, keeping the particle's scale). While the camera is
// underground (`clip_on`), streaks below the street are cut off, so no rain
// falls inside the canals; it still falls into the open Fallen Street hole
// (down to the canal water) and onto the river.
render_mode unshaded, cull_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(0.78, 0.84, 1.0, 0.3);
uniform bool clip_on = false;
uniform vec2 hole = vec2(62.0, 80.0);
uniform float hole_floor = -6.4;
uniform vec2 river = vec2(82.0, 120.0);
uniform float river_floor = -0.75;

varying vec3 world_pos;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	vec3 right = normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
	world_pos = origin + right * VERTEX.x * sx + vec3(0.0, VERTEX.y * sy, 0.0);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world_pos, 1.0);
}

void fragment() {
	if (clip_on) {
		float floor_y = 0.0;
		if (world_pos.x > hole.x && world_pos.x < hole.y) {
			floor_y = hole_floor;
		} else if (world_pos.x > river.x && world_pos.x < river.y) {
			floor_y = river_floor;
		}
		if (world_pos.y < floor_y) {
			discard;
		}
	}
	ALBEDO = tint.rgb;
	ALPHA = tint.a;
}
