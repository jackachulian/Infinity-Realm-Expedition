shader_type spatial;
render_mode unshaded;

uniform sampler2D slash_gradient : source_color, filter_nearest;

// Script will animate this from 0 to 1
uniform float t : hint_range(0.0, 1.0) = 0.0;

// true for swing left-to-right, false for swing right-to-left
uniform bool is_left_to_right = true;

void fragment() {
	float normalized_y = (UV.y - 0.1667) * 6.0;
	float normalized_x;
	if (is_left_to_right) {
		normalized_x = UV.x;
	} else {
		normalized_x = 1.0 - UV.x;
	}

	float shape = normalized_x - normalized_y - t;
	//
	if (shape <= 0.0) {
		discard; 
	} else {
		vec4 color = texture(slash_gradient, vec2(clamp(shape, 0.01, 0.99), 0));
		ALBEDO = color.rgb;
		ALPHA = color.a;
	}
	//
	//ALBEDO = vec3(normalized_x, normalized_y, 0);
}