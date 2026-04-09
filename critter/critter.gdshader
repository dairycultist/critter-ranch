shader_type spatial;

uniform sampler2D tex : filter_nearest, source_color;
uniform bool transparent = false;
uniform float shadow : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	
	if (transparent && int(FRAGCOORD.x) % 2 == int(FRAGCOORD.y) % 2) {
		discard;
	}
	
	ALBEDO = texture(tex, UV).rgb;
}

void light() {
	
	DIFFUSE_LIGHT += (step(0.0, dot(NORMAL, LIGHT)) * shadow + 1.0 - shadow);
}