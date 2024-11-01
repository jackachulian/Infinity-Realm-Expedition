shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform float WaveSpeed = 0.00999999977648;
uniform sampler2D tex_frg_19;
uniform sampler2D tex_frg_11;
uniform float WaveIntensity = 0.20000000298023;
uniform vec4 WaveColor : source_color = vec4(0.000000, 1.000000, 0.986607, 1.000000);
uniform vec4 WaterColor : source_color = vec4(0.000000, 0.169643, 1.000000, 1.000000);
uniform float FoamSize = 0.10000000149012;
uniform sampler2D depth_tex_frg_2 : hint_depth_texture;
uniform float WaterOpacity = 0.40000000596046;



void fragment() {
// FloatParameter:23
	float n_out23p0 = WaveSpeed;


// FloatOp:24
	float n_in24p1 = -1.00000;
	float n_out24p0 = n_out23p0 * n_in24p1;


// Input:21
	float n_out21p0 = TIME;


// UVFunc:20
	vec2 n_out20p0 = vec2(n_out21p0) * vec2(n_out24p0) + UV;


// Texture2D:19
	vec4 n_out19p0 = texture(tex_frg_19, n_out20p0);


// Input:18
	float n_out18p0 = TIME;


// UVFunc:17
	vec2 n_out17p0 = vec2(n_out18p0) * vec2(n_out23p0) + UV;


// Texture2D:11
	vec4 n_out11p0 = texture(tex_frg_11, n_out17p0);


// Mix:22
	float n_in22p2 = 0.50000;
	float n_out22p0 = mix(n_out19p0.x, n_out11p0.x, n_in22p2);


// FloatFunc:13
	float n_out13p0 = round(n_out22p0);


// FloatParameter:28
	float n_out28p0 = WaveIntensity;


// FloatOp:14
	float n_out14p0 = n_out13p0 * n_out28p0;


// ColorParameter:27
	vec4 n_out27p0 = WaveColor;


// VectorOp:15
	vec3 n_out15p0 = vec3(n_out14p0) * vec3(n_out27p0.xyz);


// ColorParameter:26
	vec4 n_out26p0 = WaterColor;


// VectorOp:12
	vec3 n_out12p0 = n_out15p0 + vec3(n_out26p0.xyz);


// FloatParameter:29
	float n_out29p0 = FoamSize;


	float n_out2p0;
// ProximityFade:2
	{
		float __depth_tex = texture(depth_tex_frg_2, SCREEN_UV).r;
		vec4 __depth_world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, __depth_tex, 1.0);
		__depth_world_pos.xyz /= __depth_world_pos.w;
		n_out2p0 = clamp(1.0 - smoothstep(__depth_world_pos.z + n_out29p0, __depth_world_pos.z, VERTEX.z), 0.0, 1.0);
	}


// FloatFunc:3
	float n_out3p0 = 1.0 - n_out2p0;


// FloatFunc:4
	float n_out4p0 = round(n_out3p0);


// FloatParameter:30
	float n_out30p0 = WaterOpacity;


// FloatOp:10
	float n_out10p0 = n_out4p0 + n_out30p0;


// FloatOp:25
	float n_in25p1 = 1.00000;
	float n_out25p0 = n_out4p0 * n_in25p1;


// Output:0
	ALBEDO = n_out12p0;
	ALPHA = n_out10p0;
	EMISSION = vec3(n_out25p0);


}