shader_type spatial;

uniform vec3 grass_color : source_color;
uniform vec3 rock_color : source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	//ALBEDO = COLOR.rgb;
	vec3 world_normal = (INV_VIEW_MATRIX * vec4(NORMAL.xyz, 0.0)).xyz;
	
	if (world_normal.y > 0.25) {
		ALBEDO = grass_color;
	} else {
		ALBEDO = rock_color;
	}
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
