shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_prepass_alpha;

void fragment() {
	if (fract((floor(FRAGCOORD.x) + floor(FRAGCOORD.y)) / 2.0) < 0.5) {
		ALPHA = 0.0;
	} else {
		ALPHA = 1.0;
	}
	
	ALBEDO = vec3(1, 0.5, 0.5);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
