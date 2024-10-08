shader_type spatial;
render_mode unshaded;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float center = 0.25;
	float maxDistance = 0.0833 * UV.x;
	
	if (abs(UV.y - center) < maxDistance) {
		ALBEDO = vec3(1);
	} else {
		//ALBEDO = vec3(0.25);
		discard;
	}
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
