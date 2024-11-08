shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D color_map : source_color;


void fragment() {
	float edge_distance = max(distance(0.5, clamp(UV.x, 0.01, 0.99)), distance(0.5, clamp(UV.y, 0.01, 0.99)));

	vec4 border_color = texture(color_map, vec2(edge_distance * 2.0, 0));
	ALBEDO = border_color.rgb;
	ALPHA = border_color.a;
}