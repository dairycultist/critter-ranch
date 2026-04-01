shader_type spatial;

// adapted from https://godotshaders.com/shader/pbr-glass/

uniform sampler2D tex : filter_nearest, source_color;
uniform bool transparent = false;

render_mode diffuse_burley, specular_schlick_ggx, blend_mix;

group_uniforms roughness;
uniform float roughness : hint_range(0.0, 1.0) = 0.15;

group_uniforms misc;
uniform vec4 edge_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// START DISPLACEMENT STUFF /////

group_uniforms displacement;
uniform sampler2D displace: repeat_enable, source_color; // linear color

varying float d;

void vertex() {
	
	d = max(0.1, texture(displace, UV).r * 2.0); // prevent it from being 0.0 because things get laggy fast
	
	// determine vertex displacement from the object’s local origin
	VERTEX = VERTEX * d;
}

// END DISPLACEMENT STUFF /////

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
	
	// use displace to darken color where squished
	ALBEDO = texture(tex, vec2(0.0, 0.0)).rgb * pow(d, 1.3) + edge_color.rgb * edge_color.a * fresnel;
	
	ROUGHNESS = roughness;
}