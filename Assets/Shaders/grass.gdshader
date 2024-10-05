shader_type spatial;
uniform float grassNoiseScale = 8;

// Color gradient textures
uniform sampler2D grassGradient : source_color, filter_nearest;

// -- Noise textures
// grass noise. will add brightness to grass if above grey and lower brightness if below gray.
uniform sampler2D grassNoise : source_color;

varying vec3 position;

void vertex() {
	position = VERTEX;
}

void fragment() {
	float colorNoise = texture(grassNoise, vec2(position.x, position.z) / grassNoiseScale).r;
	float colorHeight = clamp(colorNoise, 0.01, 0.99);
	// Use the height in heightmap space (stored in vertex color) to get the grass color
	vec3 grassAlbedo = texture(grassGradient, vec2(colorHeight, 0)).rgb;
	ALBEDO = grassAlbedo;
}

void light() {
    DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * 0.5 * LIGHT_COLOR;
}