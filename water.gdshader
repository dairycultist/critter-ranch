shader_type spatial;
render_mode blend_mix, cull_back, specular_disabled, unshaded;

uniform float foam_cutoff : hint_range(0., 1.) = 0.5;
uniform float scale = 8.0;
uniform vec4 water_color : source_color;

uniform sampler3D vornoi_noise;

// https://godotshaders.com/shader/parallax-mapping/

uniform sampler2D albedo_tex : source_color, hint_default_black, filter_nearest, repeat_enable;
// controls depth level of parallax effect
uniform float depth_scale = 0.1;
// controls if values outside the mesh bounds are sampled
uniform bool discard_boundaries = false;

// converts provided UV coordinates to parallax UV coordinates
vec2 get_parallax_uvs(vec2 uv, vec3 view_dir) {
	
	vec2 vec_p = view_dir.xy / view_dir.z * -depth_scale;

	vec2 final_tex_coords = uv * 0.0 + uv - vec_p * (1.0 - 0.0);

	return final_tex_coords;
}

varying mat3 TBN;
void vertex() {
	
	UV = UV * scale + TIME * 0.01;

	mat4 model = transpose(inverse(MODELVIEW_MATRIX));
	
	TBN = mat3(
		-(model * vec4(TANGENT, 0.0)).xyz,
		(model * vec4(BINORMAL, 0.0)).xyz,
		(model * vec4(NORMAL, 0.0)).xyz
	);
}

void fragment() {
	
	vec3 view_dir = normalize(normalize(-VERTEX) * TBN);

	vec2 parallax_uv = get_parallax_uvs(UV, view_dir);

	if (discard_boundaries) {
		if (parallax_uv.x > 1.0 || parallax_uv.x < 0.0 || parallax_uv.y > 1.0 || parallax_uv.y < 0.0) {
			discard;
		}
	}
	
	float fac = 1.0 - step(pow(texture(vornoi_noise, vec3(UV, sin(TIME * 0.04) * 0.3)).r, 8.0), foam_cutoff);
	float parallax_fac = 1.0 - step(pow(texture(vornoi_noise, vec3(parallax_uv, sin(TIME * 0.04) * 0.3)).r, 8.0), foam_cutoff);
	
	ALBEDO =
		vec3(fac)
		+ water_color.rgb * vec3((1.0 - parallax_fac) * 0.5 + 0.5);
}