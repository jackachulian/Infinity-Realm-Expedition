shader_type spatial;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float center = 0.1875;
	float maxDistance = 0.0625 * UV.x;
	
	if (abs(UV.y - center) < maxDistance) {
		ALBEDO = vec3(1);
	} else {
		discard;
	}
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
