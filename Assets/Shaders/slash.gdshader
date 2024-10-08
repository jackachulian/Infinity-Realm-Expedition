shader_type spatial;
render_mode unshaded;

uniform sampler2D slash_gradient : source_color, filter_nearest;

// Script will animate this from 0 to 1
uniform float t : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float normalized_y = (UV.y - 0.1667) * 6.0;
	float center_y = 0.5;
	float shape = normalized_y + UV.x - 1.0 - t;
	
	if (shape <= 0.0) {
		discard; 
	} else {
		vec4 color = texture(slash_gradient, vec2(clamp(shape, 0.00, 1.00), 0));
		ALBEDO = color.rgb;
		ALPHA = color.a;
	}
}