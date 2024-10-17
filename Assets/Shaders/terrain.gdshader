shader_type spatial;

// Ledge
uniform float ledgeTopThickness : hint_range(0, 1) = 0.5;
uniform float ledgeBottomThickness : hint_range(0, 1) = 0;

// Floor vars
uniform float rockPathThreshold = 0.25;
uniform float rockPathNoiseAmplitude = 0.25;

// Noise tiling
uniform float grassNoiseScale = 8;
uniform float rockWallNoiseScale = 8;
uniform float rockLedgeNoiseScale = 8;
uniform float rockPathNoiseScale = 8;
uniform float rockPathEdgeNoiseScale = 8;

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
uniform sampler2D rockPathNoise : source_color;
uniform sampler2D rockPathEdgeNoise : source_color;

uniform bool debug = false;

varying vec3 position;

void vertex() {
	position = NODE_POSITION_WORLD + VERTEX;
}

vec3 grass_albedo(vec4 color) {
	float colorNoise = texture(grassNoise, vec2(position.x, position.z) / grassNoiseScale).r;
	float rockEdgeNoise = texture(rockPathEdgeNoise, vec2(position.x, position.z) / rockPathEdgeNoiseScale).r;
	float threshold = rockPathThreshold + (rockEdgeNoise-0.5)*rockPathNoiseAmplitude;
	float pathColorLessen = clamp(color.r - threshold + 0.25, 0, 1);
	float colorHeight = clamp(colorNoise - min(pathColorLessen, color.r), 0, 1);
	// Use the height in heightmap space (stored in vertex color) to get the grass color
	vec3 grassAlbedo = texture(grassGradient, vec2(colorHeight, 0)).rgb;
	//return vec3(pathColorLessen);
	return grassAlbedo;
}

vec3 rock_albedo() {
	float rockBrightness = texture(rockWallNoise, position / rockWallNoiseScale).r;
	return texture(rockGradient, vec2(rockBrightness, 0)).rgb;
}

void fragment() {
	bool isWall = UV.x > 0.99 && UV.y > 0.99;

	float thicknessMult = texture(rockLedgeNoise, position / rockLedgeNoiseScale).r;

	// ==== Ledge detection
	float topLedgeValue = UV.y - 1.0 + ledgeTopThickness * thicknessMult;
	bool topLedge = topLedgeValue > 0.0;
	float bottomLedgeValue = UV.x - 1.0 + ledgeBottomThickness * thicknessMult;
	bool bottomLedge = bottomLedgeValue > 0.0;

	if (debug) {
		ALBEDO = COLOR.rgb;
		//ALBEDO = vec3(UV.x, UV.y, 0);
		//ALBEDO = NORMAL;
	}

	// ==== Walls
	else if (isWall) {
		ALBEDO = rock_albedo();
	}
	// ==== Ledges
	else if (topLedge || bottomLedge) {
		// Rock ledge albedo
		float rockBrightness = texture(rockWallNoise, position / rockWallNoiseScale).r;
		float ledgeRockBrightness = texture(ledgeRockBrightnessGradient, vec2(rockBrightness, 0)).r;
		float ledgeEdgeBrightness = texture(ledgeEdgeBrightnessGradient, vec2(max(topLedgeValue / (ledgeTopThickness * thicknessMult), bottomLedgeValue / (ledgeBottomThickness * thicknessMult)), 0)).r;
		ALBEDO = texture(rockGradient, vec2(ledgeRockBrightness * ledgeEdgeBrightness, 0)).rgb;
	}
	// ==== Floors
	else {
		float rockEdgeNoise = texture(rockPathEdgeNoise, vec2(position.x, position.z) / rockPathEdgeNoiseScale).r;
		float threshold = clamp(rockPathThreshold + (rockEdgeNoise-0.5)*rockPathNoiseAmplitude, 0, 1);
		if (COLOR.r > threshold) {
			float pathNoise = texture(rockPathNoise, vec2(position.x, position.z) / rockPathNoiseScale).r;
			float scaledPathNoise = clamp((pathNoise+0.25-COLOR.r*0.5)*0.5 + 0.15, 0.01, 0.99);
			ALBEDO = texture(rockGradient, vec2(1.0-scaledPathNoise, 0)).rgb;
		} else {
			ALBEDO = grass_albedo(COLOR);
		}
	}

	EMISSION = vec3(0);
}

//void light() {
    //DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * 0.5 * LIGHT_COLOR;
//}