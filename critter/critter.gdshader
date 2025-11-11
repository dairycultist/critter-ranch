shader_type spatial;

uniform sampler2D tex : filter_nearest, source_color;
uniform bool transparent = false;

void fragment() {

	if (transparent && int(FRAGCOORD.x) % 2 == int(FRAGCOORD.y) % 2) {
		discard;
	}
	
	ALBEDO = texture(tex, UV).rgb;
	SPECULAR = 0.0;
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
}