extends MeshInstance3D

var w: int = 4
var h: int = 4
var mesh_radius: float = 1.0

func _ready() -> void:
	
	var img: Image = Image.create_empty(w, h, false, Image.FORMAT_R8)

	img.fill(Color.BLACK)
	
	img.set_pixel(1, 1, Color.RED)

	var img_texture = ImageTexture.create_from_image(img)
	
	#img_texture.update()

	get_surface_override_material(0).set("shader_parameter/displace", img_texture);

# Texture that constantly gets updated based on a limited set of raycast nodes
# that are generated at @tool update (one for each pixel) which writes to a
# texture generated at start (that crucially wraps)
# We add this to merge game and we will be happy

# Can also use that texture to darken color
