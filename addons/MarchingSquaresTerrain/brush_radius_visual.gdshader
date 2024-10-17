shader_type spatial;
render_mode unshaded, depth_test_disabled;

uniform sampler2D curve_texture : source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float t = 1.0 - distance(vec2(UV.x, UV.y), vec2(0.25, 0.75)) * 4.0;
	float sample = texture(curve_texture, vec2(clamp(t, 0.01, 0.99), 0)).r;
	ALPHA = clamp(sample, 0, 1) * 0.6;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
