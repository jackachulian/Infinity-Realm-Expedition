shader_type spatial;
render_mode depth_prepass_alpha;

uniform float grassNoiseScale = 64;

uniform sampler2D grassTexture : source_color, filter_nearest;

// Color gradient textures
uniform sampler2D grassGradient : source_color, filter_nearest;

// -- Noise textures
// grass noise. will add brightness to grass if above grey and lower brightness if below gray.
uniform sampler2D grassNoise : source_color;

uniform sampler2D windNoise : source_color;

//uniform sampler2D grassExtraNoise : source_color;

//uniform float extraNoiseStrength = 0.1;

varying vec3 position;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			MAIN_CAM_INV_VIEW_MATRIX[0],
			MAIN_CAM_INV_VIEW_MATRIX[1],
			MAIN_CAM_INV_VIEW_MATRIX[2],
			MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	
	position = NODE_POSITION_WORLD;
	
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}

void fragment() {
	float noise = texture(grassNoise, vec2(position.x, position.z) / grassNoiseScale).r;
	//float extraNoise = texture(grassExtraNoise, vec2(position.x, position.z) / grassNoiseScale).r * extraNoiseStrength;
	float noiseSum = clamp(noise, 0.01, 0.99);
	// Use the height in heightmap space (stored in vertex color) to get the grass color
	vec3 grassAlbedo = texture(grassGradient, vec2(noiseSum, 0)).rgb;
	ALBEDO = grassAlbedo;
	
	ALPHA = texture(grassTexture, UV).a;
}

void light() {
    DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * 0.5 * LIGHT_COLOR;
}