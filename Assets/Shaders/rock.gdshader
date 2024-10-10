shader_type spatial;

uniform float rockNoiseScale = 8;
uniform sampler2D rockGradient : source_color, filter_nearest;
uniform sampler3D rockWallNoise : source_color;

varying vec3 position;

void vertex() {
	position = NODE_POSITION_WORLD + VERTEX;
}

void fragment() {
	float rockBrightness = texture(rockWallNoise, position / rockNoiseScale).r;
	ALBEDO = texture(rockGradient, vec2(rockBrightness, 0)).rgb;
}

void light() {
    DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * 0.5 * LIGHT_COLOR;
}