shader_type spatial;

uniform sampler2D displace: repeat_enable;

varying float d;

void vertex() {
	
	d = max(0.5, texture(displace, UV).r); // prevent it from being 0.0 because things get laggy fast
	
	// determine vertex displacement from the object’s local origin
	VERTEX = VERTEX * d;
}

void fragment() {
	
	ALBEDO = vec3(d);
	
	// TODO use displace to darken color where squished
}