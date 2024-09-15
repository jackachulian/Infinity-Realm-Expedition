shader_type spatial;

uniform vec3 grass_color : source_color;
uniform vec3 rock_color : source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = mix(grass_color, rock_color, max(UV.x, UV.y));
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
