shader_type spatial;

uniform float ledgeTopThickness : hint_range(0, 1) = 0.5;
uniform float ledgeBottomThickness : hint_range(0, 1) = 0;

void vertex() {
	COLOR.rgb = VERTEX;
}

void fragment() {
	bool isWall = UV.x > 0.99 && UV.y > 0.99;

	// ==== Ledge detection
	bool topLedge = UV.y > 1.0 - ledgeTopThickness;
	bool bottomLedge = UV.x > 1.0 - ledgeBottomThickness;
	bool ledge = topLedge || bottomLedge;



	if (ledge) {
		ALBEDO = vec3(UV.x, UV.y, 0);
	} else {
		//ALBEDO = vec3(UV.x * 0.5, UV.y * 0.5, 0);
		ALBEDO = vec3(0);
	}
	//ALBEDO = vec3(UV.x, UV.y, 0);
	//ALBEDO = vec3(UV2.x, UV2.y, 0);
	//ALBEDO = COLOR.rgb;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
