shader_type spatial;

uniform sampler2D tex : filter_nearest, source_color;
uniform bool transparent = false;
uniform float shadow : hint_range(0.0, 1.0) = 0.5;

// START DISPLACEMENT STUFF /////

group_uniforms displacement;
uniform sampler2D displace: repeat_enable, source_color; // linear color

varying float d;

vec2 vec3_to_uv(vec3 pos) {
	
	// https://en.wikipedia.org/wiki/UV_mapping#Finding_UV_on_a_sphere
	return vec2(
		0.5 + atan(pos.z, pos.x) / TAU,
		0.5 + asin(pos.y) / PI
	);
}

void vertex() {
	
	d = max(0.1, texture(displace, vec3_to_uv(normalize(VERTEX))).r * 2.0); // prevent it from being 0.0 because things get laggy fast
	
	// determine vertex displacement from the object’s local origin
	VERTEX = VERTEX * d;
}

// END DISPLACEMENT STUFF /////

void fragment() {
	
	if (transparent && int(FRAGCOORD.x) % 2 == int(FRAGCOORD.y) % 2) {
		discard;
	}
	
	ALBEDO = texture(tex, vec2(0.0)).rgb * d;
}

void light() {
	
	DIFFUSE_LIGHT += (step(0.0, dot(NORMAL, LIGHT)) * shadow + 1.0 - shadow);
}