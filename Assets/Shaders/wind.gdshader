shader_type spatial;

vec2 random2(vec2 p) {
	return fract(sin(vec2(
		dot(p, vec2(127.32, 231.4)),
		dot(p, vec2(12.3, 146.3))
	)) * 231.23);
}

float worley2(vec2 p) {
	float dist = 1.0;
	vec2 i = floor(p);
	vec2 f = fract(p);
	for (int y=-1; y<=1; y++) {
		for (int x=-1; x<=1; x++) {
			vec2 n = vec2(float(x), float(y));
			vec2 diff = n + random2(i + n) - f;
			dist = min(dist, length(diff));
		}
	}
	return dist;
}

void fragment() {
	ALBEDO = vec3(worley2((UV * 2.0) + (TIME * vec2(1.0, 0.0))));
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
