shader_type spatial;

uniform float foam_cutoff : hint_range(0., 1.) = 0.5;
uniform float scale = 8.0;
uniform vec4 water_color : source_color;

uniform sampler3D vornoi_noise;

void fragment() {
	
	float fac = 1.0 - step(pow(texture(vornoi_noise, vec3(UV * scale + TIME * 0.01, sin(TIME * 0.04) * 0.3)).r, 8.0), foam_cutoff);
	
	ALBEDO = vec3(fac) + water_color.rgb * vec3(1.0 - fac);
}