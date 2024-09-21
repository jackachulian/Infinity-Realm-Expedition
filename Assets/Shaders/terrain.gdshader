shader_type spatial;

// Ledge
uniform float ledgeTopThickness : hint_range(0, 1) = 0.5;
uniform float ledgeBottomThickness : hint_range(0, 1) = 0;
uniform float ledgeBrightMin : hint_range(0, 1) = 0.5;

// Noise tiling
uniform float grassNoiseTiling = 8;
uniform float rockWallNoiseTiling = 8;
uniform float rockLedgeNoiseTiling = 8;

// Brightnesss gradient textures
uniform sampler2D ledgeBrightnessGradient : source_color;

// Color gradient textures
uniform sampler2D grassGradient : source_color, filter_nearest;
uniform sampler2D rockGradient : source_color, filter_nearest;

// -- Noise textures
// grass noise. will add brightness to grass if above grey and lower brightness if below gray.
uniform sampler2D grassNoise : source_color;
uniform sampler3D rockWallNoise : source_color;
uniform sampler3D rockLedgeNoise : source_color;

void fragment() {
	bool isWall = UV.x > 0.99 && UV.y > 0.99;
	
	float thicknessMult = texture(rockLedgeNoise, COLOR.xyz * rockLedgeNoiseTiling).r;

	// ==== Ledge detection
	float topLedgeValue = UV.y - 1.0 + ledgeTopThickness * thicknessMult;
	bool topLedge = topLedgeValue > 0.0;
	float bottomLedgeValue = UV.x - 1.0 + ledgeBottomThickness * thicknessMult;
	bool bottomLedge = bottomLedgeValue > 0.0;

	float rockBrightness = texture(rockWallNoise, COLOR.xyz * rockWallNoiseTiling).r;
	
	// ==== Walls
	if (isWall) {
		ALBEDO = texture(rockGradient, vec2(rockBrightness, 0)).rgb;
	}
	// ==== Ledges
	else if (topLedge || bottomLedge) {
		float ledgeBrightness = texture(ledgeBrightnessGradient, vec2(rockBrightness, 0)).r;
		ALBEDO = texture(rockGradient, vec2(ledgeBrightness, 0)).rgb;
	}
	// ==== Floors
	else {
		float colorHeightNoise = texture(grassNoise, vec2(COLOR.x, COLOR.z)*grassNoiseTiling).r;
		float colorHeight = clamp(COLOR.y + colorHeightNoise - 0.5, 0.01, 0.99);
		// Use the height in heightmap space (stored in vertex color) to get the grass color
		vec3 grassAlbedo = texture(grassGradient, vec2(colorHeight, 0)).rgb;
		ALBEDO = grassAlbedo;
	}
}

void light() {
    DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * 0.5 * LIGHT_COLOR;
}