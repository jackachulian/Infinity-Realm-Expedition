shader_type spatial;
render_mode depth_prepass_alpha, cull_disabled;

uniform sampler2D leaf_texture : source_color, filter_nearest;

uniform vec3 albedo : source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 tex = texture(leaf_texture, UV);
	ALBEDO = albedo;
	ALPHA = tex.a;
	
	//ALBEDO = vec3(UV.x, UV.y, 0);
}

void light() {
	float light_strength = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	light_strength = round(light_strength * 4.0) / 4.0;
	vec3 light = light_strength * ATTENUATION * 0.5 * LIGHT_COLOR;
	DIFFUSE_LIGHT += light;
}
