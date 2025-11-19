shader_type spatial;
render_mode blend_mix, cull_back, specular_disabled;

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

	ALBEDO = texture(albedo_tex, parallax_uv).rgb;
}

void light() {
	DIFFUSE_LIGHT = vec3(1.);
}