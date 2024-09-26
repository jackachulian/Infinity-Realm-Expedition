shader_type spatial;
render_mode unshaded, depth_test_disabled;

void fragment() {
	if (fract((floor(FRAGCOORD.x) + floor(FRAGCOORD.y)) / 2.0) < 0.5) {
		discard;
	}
	
	ALBEDO = vec3(1, 0.5, 0.5);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
