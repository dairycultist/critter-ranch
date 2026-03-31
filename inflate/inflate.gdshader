shader_type spatial;

uniform sampler2D displace: repeat_enable;

varying float d;

void vertex() {
	
	d = texture(displace, UV).r;
	
	// determine vertex displacement from the object’s local origin
	VERTEX = VERTEX * d;
}

void fragment() {
	
	ALBEDO = vec3(d);
	
	// TODO use displace to darken color where squished
}