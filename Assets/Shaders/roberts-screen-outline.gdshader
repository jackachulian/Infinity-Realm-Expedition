shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D screen_texture : source_color, hint_screen_texture, filter_nearest;
uniform sampler2D depth_texture : source_color, hint_depth_texture, filter_nearest;
uniform sampler2D normal_texture : source_color, hint_normal_roughness_texture, filter_nearest;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

uniform float offset_multiplier = 1.0;

void fragment() {
	vec2 texel_size = 1.0 / VIEWPORT_SIZE.xy;

	vec2 tr_uv = SCREEN_UV + texel_size * offset_multiplier;
	vec2 bl_uv = SCREEN_UV + texel_size * offset_multiplier;
	vec2 tl_uv = SCREEN_UV + vec2(-texel_size.x * offset_multiplier, texel_size.y * offset_multiplier);
	vec2 br_uv = SCREEN_UV + vec2(-texel_size.x * offset_multiplier, texel_size.y * offset_multiplier);

	float d0 = getDepth(tr_uv, INV_PROJECTION_MATRIX);
	float d1 = getDepth(bl_uv, INV_PROJECTION_MATRIX);
	float d2 = getDepth(tl_uv, INV_PROJECTION_MATRIX);
	float d3 = getDepth(br_uv, INV_PROJECTION_MATRIX);

	vec3 n0 = texture(normal_texture, tr_uv).rgb * 2.0 - 1.0;
	vec3 n1 = texture(normal_texture, bl_uv).rgb * 2.0 - 1.0;
	vec3 n2 = texture(normal_texture, tl_uv).rgb * 2.0 - 1.0;
	vec3 n3 = texture(normal_texture, br_uv).rgb * 2.0 - 1.0;

	ALBEDO = vec3(0,0,0);
}

float getDepth(vec2 uv, mat4 mat) {
	float depth = texture(depth_texture, uv).r;
	vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
	vec4 view = mat * vec4(ndc, 1.0);
	view.xyz /= view.w;

	return view.z;
}