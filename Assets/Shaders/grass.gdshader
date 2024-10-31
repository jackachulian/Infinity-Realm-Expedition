shader_type spatial;
render_mode depth_prepass_alpha;

uniform float grassHeight = 1.5;
uniform float grassHeightVariance = 0.5;
uniform float grassHeightScale = 48;
uniform float grassNoiseScale = 64;
uniform sampler2D grassTexture : source_color, filter_nearest;
uniform float grassExtraNoiseScale = 128;
uniform float grassExtraNoiseStrength = 0.25;

// Color gradient textures
uniform sampler2D grassGradient : source_color, filter_nearest;

// -- Noise textures
// grass noise. will add brightness to grass if above grey and lower brightness if below gray.
uniform sampler2D grassNoise : source_color;

uniform sampler2D windNoise : source_color;

const int MAX_WIND_POINTS = 10;
uniform vec3[MAX_WIND_POINTS] wind_points;
uniform vec2[MAX_WIND_POINTS] wind_vectors;
uniform float[MAX_WIND_POINTS] wind_radii;
uniform int wind_point_count;  // Number of active wind points

uniform vec3 ambient_wind_vector = vec3(1, 0, 0.25);
uniform float ambient_wind_speed = 1.5;
uniform float ambient_wind_scale = 32.0;
uniform float ambient_wind_resolution = 5;

varying float wind_noise;
varying float ambient_wind_noise;
varying vec3 position;
varying float highest_influence;
varying vec2 wind_vector_sum;
varying vec3 total_wind;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	if (length(vec3(MODEL_MATRIX[0].xyz)) == 0.0) {
		
	} else {
		position = NODE_POSITION_WORLD;
		ambient_wind_noise = texture(windNoise, (vec2(NODE_POSITION_WORLD.x, NODE_POSITION_WORLD.z) + TIME * ambient_wind_speed) / ambient_wind_scale).r;
		ambient_wind_noise = round(ambient_wind_noise*ambient_wind_resolution) / ambient_wind_resolution;
		
		vec3 screen_wind_vector = (VIEW_MATRIX * vec4(ambient_wind_vector, 0)).xyz;
		
		// ambient wind: point in direction of ambient wind vector. 75% in front of random, 25% behind
		vec3 ambient_wind = ((ambient_wind_noise - 0.25) + UV.y) * ( 1.0 - UV.y) * screen_wind_vector;
		
		position = NODE_POSITION_WORLD;
		wind_vector_sum = vec2(0.0);
		highest_influence = 0.0;
	   	
		float point_wind_noise = texture(windNoise, (vec2(NODE_POSITION_WORLD.x, NODE_POSITION_WORLD.z) + TIME * ambient_wind_speed * 3.0) / (ambient_wind_scale * 0.75)).r;
		point_wind_noise = round(point_wind_noise*ambient_wind_resolution) / ambient_wind_resolution;
		
	    // Loop through wind points
	    for (int i = 0; i < wind_point_count; i++) {
	        vec3 point = wind_points[i];
			float radius = wind_radii[i];
	        float dist = distance(position, point);
	        // Only affect vertices within the wind_radius
	        if (dist < radius) {
				vec2 vector = wind_vectors[i];
				vec2 screen_vector = (VIEW_MATRIX * vec4(vector.x, 0, vector.y, 0)).xz;
	            // Calculate influence based on distance (closer = stronger)
	            float influence = 1.0 - (dist / radius);
				highest_influence = max(influence, highest_influence);
				vec2 wind = ((point_wind_noise - 0.125) + UV.y) * ( 1.0 - UV.y) * screen_vector;
	            wind_vector_sum += wind * influence;
				//ALBEDO = vec3(influence + wind_noise - 0.5);
	        }
	    }
		
		total_wind = ambient_wind + vec3(wind_vector_sum.x, 0, wind_vector_sum.y);
		float total_wind_length = length(total_wind);
		
		float grass_height_noise = texture(windNoise, (vec2(NODE_POSITION_WORLD.x, NODE_POSITION_WORLD.z)) / grassHeightScale).r;
		float grass_height = grassHeight + (grass_height_noise - 0.5)*grassHeightVariance;
		
		NORMAL = vec3(0.0, 1.0, 0.0);
		VERTEX += total_wind;
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), 
			vec4(0.0, grass_height, 0.0, 0.0), 
			vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), 
			MODEL_MATRIX[3]
		);
		
		
	}
}

void fragment() {
	float noise = texture(grassNoise, vec2(position.x, position.z) / grassNoiseScale).r;
	float added_noise = texture(windNoise, vec2(position.x, position.z) / grassExtraNoiseScale).r;
	
	//float extraNoise = texture(grassExtraNoise, vec2(position.x, position.z) / grassNoiseScale).r * extraNoiseStrength;
	float noiseSum = clamp(noise + (added_noise - 0.5)*grassExtraNoiseStrength, 0.01, 0.99);
	// Use the height in heightmap space (stored in vertex color) to get the grass color
	vec3 grassAlbedo = texture(grassGradient, vec2(noiseSum, 0)).rgb;
	ALBEDO = grassAlbedo;
	
	//if (highest_influence > 0.0) {
		//ALBEDO = vec3(ambient_wind_noise);
	//}

	ALPHA = texture(grassTexture, UV).a;
	//ALBEDO = vec3(highest_influence);
}

//void light() {
    //DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * 0.5 * LIGHT_COLOR;
//}