shader_type spatial;
render_mode blend_mix, cull_back, specular_disabled, unshaded;

uniform sampler2D depth_texture : source_color, hint_depth_texture;

uniform float foam_cutoff : hint_range(0., 1.) = 0.5;
uniform float scale = 8.0;

uniform sampler3D vornoi_noise;
uniform sampler2D perlin_noise;

uniform sampler2D color_ramp : source_color;

// adapted from https://godotshaders.com/shader/parallax-mapping/

uniform sampler2D albedo_tex : source_color, hint_default_black, filter_nearest, repeat_enable;
// controls depth level of parallax effect
uniform float depth_scale : hint_range(0., 0.04) = 0.04;

varying mat3 TBN;
void vertex() {

	mat4 model = transpose(inverse(MODELVIEW_MATRIX));
	
	TBN = mat3(
		-(model * vec4(TANGENT, 0.0)).xyz,
		(model * vec4(BINORMAL, 0.0)).xyz,
		(model * vec4(NORMAL, 0.0)).xyz
	);
}

#define FAC(uv) 1.0 - step(pow(texture(vornoi_noise, vec3(uv * scale + TIME * 0.01, sin(TIME * 0.04) * 0.3)).r, 8.0), foam_cutoff)

void fragment() {
	
	vec3 view_dir = normalize(normalize(-VERTEX) * TBN);

	// converts provided UV coordinates to parallax UV coordinates
	vec2 parallax_uv = UV - (view_dir.xy / view_dir.z * -depth_scale);

	// values outside the mesh bounds aren't sampled
	if (parallax_uv.x > 1.0 || parallax_uv.x < 0.0 || parallax_uv.y > 1.0 || parallax_uv.y < 0.0) {
		discard;
	}
	
	// foam fac
	float fac          = FAC(UV);
	float parallax_fac = FAC(parallax_uv);
	
	// depth stuff
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, texture(depth_texture, SCREEN_UV).x, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;

	vec4 object_view = INV_PROJECTION_MATRIX * vec4(vec3(SCREEN_UV * 2.0 - 1.0, FRAGCOORD.z), 1.0);
	object_view.xyz /= object_view.w;
	float linear_object_depth = -object_view.z;

	float op = 1.0;

	if (linear_depth - linear_object_depth < 100.0 && fac < foam_cutoff) {
		op = clamp((linear_depth - linear_object_depth) / depth_scale / 100.0, 0., 1.);
	}
	
	// final color
	ALBEDO =
		vec3(fac)
		+ texture(color_ramp, vec2(texture(perlin_noise, parallax_uv).r, 0.)).rgb
		* texture(color_ramp, vec2(texture(perlin_noise, parallax_uv + vec2(0.456, 0.80275)).r, 0.)).rgb
		* vec3((1.0 - parallax_fac) * 0.5 + 0.5);
		
	ALPHA = op;
}