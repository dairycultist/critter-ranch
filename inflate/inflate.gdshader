shader_type spatial;

uniform sampler2D displace: repeat_enable;

void vertex() {
	// TODO determine vertex displacement from the object’s local origin
}

void fragment() {
	
	ALBEDO = vec3(texture(displace, UV).r);
	
	// TODO use displace to darken color where squished
}