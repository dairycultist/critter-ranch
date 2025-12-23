shader_type spatial;
render_mode blend_mix, cull_back, specular_disabled, unshaded;

uniform sampler2D tex : filter_nearest, source_color;

void fragment() {
	ALBEDO = texture(tex, UV).rgb;
}
