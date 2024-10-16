shader_type spatial;

// Ledge
uniform float ledgeTopThickness : hint_range(0, 1) = 0.5;
uniform float ledgeBottomThickness : hint_range(0, 1) = 0;

// Noise tiling
uniform float grassNoiseScale = 8;
uniform float rockWallNoiseScale = 8;
uniform float rockLedgeNoiseScale = 8;

// Brightnesss gradient textures
uniform sampler2D ledgeRockBrightnessGradient : source_color;
uniform sampler2D ledgeEdgeBrightnessGradient : source_color;

// Color gradient textures
uniform sampler2D grassGradient : source_color, filter_nearest;
uniform sampler2D rockGradient : source_color, filter_nearest;

// -- Noise textures
// grass noise. will add brightness to grass if above grey and lower brightness if below gray.
uniform sampler2D grassNoise : source_color;
uniform sampler3D rockWallNoise : source_color;
uniform sampler3D rockLedgeNoise : source_color;

uniform bool debug = false;

varying vec3 position;

void vertex() {
	position = NODE_POSITION_WORLD + VERTEX;
}

void fragment() {
	bool isWall = UV.x > 0.99 && UV.y > 0.99;

	float thicknessMult = texture(rockLedgeNoise, position / rockLedgeNoiseScale).r;

	// ==== Ledge detection
	float topLedgeValue = UV.y - 1.0 + ledgeTopThickness * thicknessMult;
	bool topLedge = topLedgeValue > 0.0;
	float bottomLedgeValue = UV.x - 1.0 + ledgeBottomThickness * thicknessMult;
	bool bottomLedge = bottomLedgeValue > 0.0;

	float rockBrightness = texture(rockWallNoise, position / rockWallNoiseScale).r;

	if (debug) {
		//ALBEDO = COLOR.rgb;
		ALBEDO = vec3(UV.x, UV.y, 0);
		//ALBEDO = NORMAL;
	}

	// ==== Walls
	else if (isWall) {
		ALBEDO = texture(rockGradient, vec2(rockBrightness, 0)).rgb;
	}
	// ==== Ledges
	else if (topLedge || bottomLedge) {
		float ledgeRockBrightness = texture(ledgeRockBrightnessGradient, vec2(rockBrightness, 0)).r;
		float ledgeEdgeBrightness = texture(ledgeEdgeBrightnessGradient, vec2(max(topLedgeValue / (ledgeTopThickness * thicknessMult), bottomLedgeValue / (ledgeBottomThickness * thicknessMult)), 0)).r;
		ALBEDO = texture(rockGradient, vec2(ledgeRockBrightness * ledgeEdgeBrightness, 0)).rgb;
	}
	// ==== Floors
	else {
		float colorNoise = texture(grassNoise, vec2(position.x, position.z) / grassNoiseScale).r;
		float colorHeight = clamp(colorNoise, 0.01, 0.99);
		// Use the height in heightmap space (stored in vertex color) to get the grass color
		vec3 grassAlbedo = texture(grassGradient, vec2(colorHeight, 0)).rgb;
		ALBEDO = grassAlbedo;
	}

	EMISSION = vec3(0);
}

void light() {
    DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * 0.5 * LIGHT_COLOR;
}