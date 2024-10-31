shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

uniform sampler2D leaf_texture : source_color, filter_nearest;

uniform vec3 albedo : source_color;

uniform float shadow_size = 0.045;
uniform float shadow_blend = 0.001;
uniform float shadow_banding = 3.0;
uniform float shadow_extra_intensity = 0.0;
uniform vec4 shadow_color : source_color;
uniform vec4 light_tint : source_color;
uniform float rimlight_size = 0.921;
uniform float rimlight_blend = 0.01;
uniform float rimlight_banding = 3.0;
uniform vec4 rimlight_color : source_color;

global uniform vec3 ambient_wind_vector = vec3(1, 0, 0.25);
global uniform float ambient_wind_speed = 1.5;
global uniform float ambient_wind_scale = 32.0;
uniform float ambient_wind_resolution = 5;

const int MAX_WIND_POINTS = 10;
uniform vec3[MAX_WIND_POINTS] wind_points;
uniform vec2[MAX_WIND_POINTS] wind_vectors;
uniform float[MAX_WIND_POINTS] wind_radii;
uniform int wind_point_count;  // Number of active wind points

uniform sampler2D windNoise : source_color;

// 0 = not being hidden, 1 = fully invisible. object hider script will likely only animate this to about 0.9
uniform float hide_amount = 0.0;

void vertex() {
	float ambient_wind_noise = texture(windNoise, (vec2(NODE_POSITION_WORLD.x, NODE_POSITION_WORLD.z) + TIME * ambient_wind_speed) / ambient_wind_scale).r;
	//ambient_wind_noise = round(ambient_wind_noise*ambient_wind_resolution) / ambient_wind_resolution;
	
	vec3 screen_wind_vector = (VIEW_MATRIX * vec4(ambient_wind_vector * 0.2, 0)).xyz;
	
	vec3 ambient_wind = ((ambient_wind_noise - 0.25)) * screen_wind_vector;
	
	VERTEX += ambient_wind;
}

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void fragment() {
	if (hide_amount > 0.0) {
		ALPHA = (1.0 - hide_amount);
	}

	vec4 tex = texture(leaf_texture, UV);

	ALBEDO = albedo;
	if (tex.a < 0.5) {
		discard;
	}
}
//
//void light() {
	//float NdotL = dot(NORMAL, LIGHT);
//
	//float rounded = round(smoothstep(shadow_size, shadow_blend + shadow_size, NdotL) * shadow_banding) / shadow_banding;
	//float one_minus = 1.0 - rounded;
	//vec3 mult1 = LIGHT_COLOR * rounded * light_tint.rgb * ATTENUATION;
	//vec3 mult2 = (one_minus * 1.4 * shadow_color.rgb) - shadow_extra_intensity;
	//vec3 add1 = mult1 + mult2;
//
	//float add3  = rimlight_blend + rimlight_size;
	//float basic_fresnel = fresnel(1.0, NORMAL, VIEW);
	//float smoothed = round(smoothstep(rimlight_size, add3, basic_fresnel) * rimlight_banding) / rimlight_banding;
//
	//vec3 add2 = add1 + smoothed * rimlight_color.rgb;
	//DIFFUSE_LIGHT += ALBEDO * add2;
//}
