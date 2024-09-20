shader_type spatial;

uniform sampler2D colorMap : source_color, filter_nearest;

uniform sampler3D rockNoiseTexture : source_color;
uniform sampler2D rockGradient : source_color, filter_nearest;

uniform vec3 rockNoiseStretch = vec3(6, 24, 6);
uniform float rockNoiseAmplify = 1.5;

uniform float ledgeThickness = 0.3;
uniform float ledgeTopBrightness = 0.45;
uniform float ledgeWallTopBrightness = 0.3;
uniform float ledgeBottomBrightness = -0.3;
uniform float ledgeWallBottomBrightness = -0.15;
uniform float wallMaxGradientValue = 0.8;

void vertex() {
	COLOR.rgb = VERTEX;
}

void fragment() {
	bool isWall = abs(UV2.x - 1.0) < 0.01 && abs(UV2.y - 1.0) < 0.01;
	
	vec3 grassColor = texture(colorMap, UV).rgb;
	
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
	
	float edge = 1.0 - clamp(ledgeThickness - (rockNoise - 0.5)*rockNoiseAmplify*0.5, 0, 1);
	//float grassRockEdge = step(edge, length(UV2));
	//float grassRockEdge = step(edge, UV2.x + UV2.y);
	//float grassRockEdge = step(edge, max(UV2.x, UV2.y));
	float grassRockEdge = step(edge, max(UV2.x, UV2.y) + (UV2.x + UV2.y)*0.15);
	vec3 grassRockMix = mix(grassColor, rockColor, grassRockEdge);
	
	ALBEDO = grassRockMix;
	
	//ALBEDO = vec3(UV.x, UV.y, 0);
	//ALBEDO = vec3(UV2.x, UV2.y, 0);
	//ALBEDO = COLOR.rgb;
	//ALBEDO = vec3(rockNoise);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
