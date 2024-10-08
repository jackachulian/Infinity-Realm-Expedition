shader_type spatial;
render_mode unshaded;

// Script will animate this from 0 to 1
uniform float t : hint_range(0.0, 1.0) = 0.0;

float remap(float value, float low1, float high1, float low2, float high2) {
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

void fragment() {
	float center = 0.33;
	float x = UV.x * step(t, UV.x);
	float maxDistance = 0.1667 * pow(x, 1.5);
	
	if (abs(UV.y - center) < maxDistance) {
		ALBEDO = vec3(1);
	}
	else {
		//ALBEDO = vec3(0.25);
		discard;
	}
}