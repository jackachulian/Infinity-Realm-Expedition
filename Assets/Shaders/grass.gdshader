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
uniform float windNoiseScale = 8.0;
uniform float windTimeScale = 0.05;

const int MAX_WIND_POINTS = 10;
uniform vec3[MAX_WIND_POINTS] wind_points;
uniform vec2[MAX_WIND_POINTS] wind_vectors;
uniform float[MAX_WIND_POINTS] wind_radii;
uniform int wind_point_count;  // Number of active wind points
uniform float ambient_wind_strength = 1.5;

varying float wind_noise;
varying vec3 ambient_wind_noise;
varying vec3 position;
varying float highest_influence;
varying vec2 wind_vector_sum;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			MAIN_CAM_INV_VIEW_MATRIX[0],
			MAIN_CAM_INV_VIEW_MATRIX[1],
			MAIN_CAM_INV_VIEW_MATRIX[2],
			MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	position = NODE_POSITION_WORLD;

	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	
	wind_noise = texture(windNoise, (vec2(position.x, position.y) * TIME * windTimeScale) / windNoiseScale).r;
	wind_vector_sum = vec2(0.0);
	highest_influence = 0.0;
   	
    // Loop through wind points
    for (int i = 0; i < wind_point_count; i++) {
        vec3 point = wind_points[i];
		float radius = wind_radii[i];
        float dist = distance(position, point);
        // Only affect vertices within the wind_radius
        if (dist < radius) {
			vec2 vector = wind_vectors[i];
            // Calculate influence based on distance (closer = stronger)
            float influence = 1.0 - (dist / radius);
			highest_influence = max(influence, highest_influence);
            wind_vector_sum += vector * influence;
			//ALBEDO = vec3(influence + wind_noise - 0.5);
        }
    }

	//if (highest_influence > 0.0) {
		//// Compute the skew in the wind direction
	    //float skew_factor = wind_noise * highest_influence;
//
	    //// Apply skew to the world position, but only in the horizontal plane (X and Z)
	    //VERTEX += VERTEX.y * skew_factor * normalize(vec3(wind_vector_sum.x, 0, wind_vector_sum.y));
	//}
	
	ambient_wind_noise = texture(windNoise, (vec2(position.x, position.z) * TIME * windTimeScale) / windNoiseScale).rgb;
	ambient_wind_noise *= ambient_wind_strength;
	ambient_wind_noise.g = 0.0;
	VERTEX += VERTEX.y * normalize(ambient_wind_noise);
//
    //// Transform the vertex with the billboarded MODELVIEW_MATRIX
    //VERTEX = (inverse(VIEW_MATRIX) * vec4(position, 1.0)).xyz;
}

void fragment() {
	float noise = texture(grassNoise, vec2(position.x, position.z) / grassNoiseScale).r;
	//float extraNoise = texture(grassExtraNoise, vec2(position.x, position.z) / grassNoiseScale).r * extraNoiseStrength;
	float noiseSum = clamp(noise, 0.01, 0.99);
	// Use the height in heightmap space (stored in vertex color) to get the grass color
	vec3 grassAlbedo = texture(grassGradient, vec2(noiseSum, 0)).rgb;
	ALBEDO = grassAlbedo;
	
	if (highest_influence > 0.0) {
		ALBEDO = ambient_wind_noise;
	}

	// Random chance to flip horizontally
	//if (random(vec2(position.x, position.z)) < 0.5) {
		//ALPHA = texture(grassTexture, UV).a;
	//} else {
		//ALPHA = texture(grassTexture, vec2(1.0-UV.x, UV.y)).a;
	//}
	ALPHA = texture(grassTexture, UV).a;
}

//void light() {
    //DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * 0.5 * LIGHT_COLOR;
//}