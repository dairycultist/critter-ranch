// adapted from https://godotshaders.com/shader/pbr-glass/

shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, blend_mix;

uniform sampler2D _Albedo : filter_nearest, source_color;
uniform bool transparent = false;

uniform vec4 edge_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

float SchlickFresnel(float u) {
	float m = 1.0 - u;
	float m2 = m * m;
	return m2 * m2 * m;
}

void fragment() {
	
	if (transparent && int(FRAGCOORD.x) % 2 == int(FRAGCOORD.y) % 2) {
		discard;
	}
	
	// calculate fresnel values
	float VdotN = dot(VIEW, NORMAL);
	float fresnel = clamp(SchlickFresnel(VdotN), 0.0, 1.0);
	
	ALBEDO = texture(_Albedo, UV).rgb + edge_color.rgb * edge_color.a * fresnel;
	
	ROUGHNESS = 0.15;
	SPECULAR = 0.5;
}

void light() {
    DIFFUSE_LIGHT += clamp(smoothstep(0.0, 0.3, dot(NORMAL, LIGHT)), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR / PI;
}