shader_type spatial;

uniform sampler2D grassNoiseMap : source_color;
uniform sampler2D grassGradient : source_color, filter_nearest;
uniform float grassMaxBrightness = 0.85;
uniform float grassTopLedgeAddBrightness = 0.15;
uniform float grassBottomLedgeAddBrightness = -0.15;

uniform sampler3D rockNoiseTexture : source_color;
uniform sampler2D rockGradient : source_color, filter_nearest;
uniform vec3 rockNoiseStretch = vec3(6, 24, 6);
uniform float rockNoiseAmplify = 1.5;

uniform sampler2D rockLedgeContourTexture : source_color;
uniform float rockLedgeNoiseStretch = 5.0;

uniform float ledgeTopThickness = 0.3;
uniform float ledgeBottomThickness = 0;
uniform float ledgeTopBrightness = 0.45;
uniform float ledgeWallTopBrightness = 0.3;
uniform float ledgeBottomBrightness = -0.3;
uniform float ledgeWallBottomBrightness = -0.15;
uniform float wallMaxGradientValue = 0.8;

uniform float colorHeightCorrelation = 0.25;
uniform float colorHeightOffset = -0.25;

void vertex() {
	COLOR.rgb = VERTEX;
}

void fragment() {
	bool isWall = abs(UV2.x - 1.0) < 0.01 && abs(UV2.y - 1.0) < 0.01;

	float grassNoise = texture(grassNoiseMap, UV).r;
	float addBrightness = UV2.y * grassTopLedgeAddBrightness + UV2.x * grassBottomLedgeAddBrightness;
	float grassBrightness = clamp(grassNoise + colorHeightOffset + colorHeightCorrelation * COLOR.y + addBrightness, 0.01, min(grassMaxBrightness + addBrightness, 0.99));
	vec3 grassColor = texture(grassGradient, vec2(grassBrightness, 0)).rgb;

	float brightness;
	if (isWall) {
		brightness = mix(ledgeWallBottomBrightness, ledgeWallTopBrightness, UV.y);
	} else {
		brightness = UV2.y * ledgeTopBrightness;
		brightness = mix(brightness, ledgeBottomBrightness, UV2.x / (UV2.x + UV2.y));
	}

	float rockNoise = texture(rockNoiseTexture, COLOR.rgb / rockNoiseStretch).r;
	float rockNoiseAmplified = (rockNoise - 0.5)*rockNoiseAmplify + 0.5;
	float amplifiedBrightness = rockNoiseAmplified + brightness;
	if (isWall) {
		amplifiedBrightness *= wallMaxGradientValue;
	}
	float rockBrightness = clamp(amplifiedBrightness, 0.02, 0.98);
	vec3 rockColor = texture(rockGradient, vec2(rockBrightness, 0)).rgb;

	float thickness = ledgeBottomThickness * UV2.x;
	thickness = mix(thickness, ledgeTopThickness, UV2.y);
	float contour = texture(rockLedgeContourTexture, vec2(COLOR.x, COLOR.z) / rockLedgeNoiseStretch).r;
	thickness -= contour;
	float edge = 1.0 - clamp(thickness - (rockNoise - 0.5)*rockNoiseAmplify*0.5, 0, 1);
	if (UV2.y < 0.01 && ledgeBottomThickness < 0.01) {
		edge = 999.0;
	}
	//float grassRockEdge = step(edge, length(UV2));
	//float grassRockEdge = step(edge, UV2.x + UV2.y);
	//float grassRockEdge = step(edge, max(UV2.x, UV2.y));
	float grassRockEdge = step(edge, max(UV2.x, UV2.y) + (UV2.x + UV2.y)*0.15);
	vec3 grassRockMix = mix(grassColor, rockColor, grassRockEdge);

	ALBEDO = grassRockMix;
	//ALBEDO = vec3(contour);
	//ALBEDO = vec3(UV.x, UV.y, 0);
	//ALBEDO = vec3(UV2.x, UV2.y, 0);
	//ALBEDO = COLOR.rgb;
	//ALBEDO = vec3(rockNoise);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
