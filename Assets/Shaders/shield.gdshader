shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec2 scale = vec2(8.0);
uniform float radius = 1.0;
uniform float power = 1.0;
uniform bool hide_incomplete = false;
uniform sampler2D color_map : source_color;

float is_in_hex(float hex_radius, vec2 local_point) {
	const vec2 AXIS[3] = {
		vec2(sqrt(3)*0.5, 0.5),
		vec2(0.0, 1.0),
		vec2(-sqrt(3)*0.5, 0.5)
	};
	float max_r = 0.0;
	for (int i = 0; i < 3; i++) {
		float r = dot(local_point, AXIS[i]);
		r /= (sqrt(3)*0.5*hex_radius);
		max_r = max(max_r, abs(r));
	}
	return max_r;
}

float snap_to_center(float local_coord, float hex_radius) {
	return float(floor((local_coord+hex_radius)/(2.0*hex_radius)))*2.0*hex_radius;
}

vec2 calculate_local_center(vec2 uv, float r) {
	float y_coord_1 = snap_to_center(uv.y, r);
	float x_coord_1 = snap_to_center(uv.x, r*sqrt(3));
	vec2 point_1 = vec2(x_coord_1, y_coord_1);
	
	float x_coord_2 = snap_to_center(uv.x - r*sqrt(3), r*sqrt(3));
	float y_coord_2 = snap_to_center(uv.y - r, r);
	vec2 point_2 = vec2(x_coord_2, y_coord_2) + vec2(r*sqrt(3), r);
	
	if (length(uv - point_1) < length(uv - point_2)) {
		return point_1;
	} else {
		return point_2;
	}
}

void fragment() {
	vec2 uv = vec2((UV.x - 0.5) * scale.x, (UV.y - 0.5) * scale.y);
	float r = (radius * sqrt(3))/2.0;
	vec2 local_center = calculate_local_center(uv, r);
	vec2 local_coords = uv - local_center;
	
	if (hide_incomplete && (
			abs(local_center.x) > scale.x/2.0 - radius ||
			abs(local_center.y) > scale.y/2.0 - radius
		)
	) {
		ALPHA = 0.0;
	} else {
		float rad = is_in_hex(radius, local_coords);
		vec4 color = texture(color_map, vec2(rad, 0));
		ALBEDO = color.rgb;
		ALPHA = color.a;
	}
}