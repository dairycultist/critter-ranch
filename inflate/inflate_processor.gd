extends MeshInstance3D

@export var w: int = 4
@export var h: int = 4
@export var mesh_radius: float = 1.0

var _displace: Image
var _displace_texture: ImageTexture

# polar coordinate conversion
func uv_to_vec3(u: float, v: float) -> Vector3:
	
	u = u * TAU
	v = (v - 0.5) * PI
	
	# +z direction is u=0
	return Vector3(sin(u) * cos(v), -sin(v), cos(u) * cos(v)) * mesh_radius

func _ready() -> void:
	
	_displace = Image.create_empty(w, h, false, Image.FORMAT_R8)

	_displace.fill(Color.BLACK)

	_displace_texture = ImageTexture.create_from_image(_displace)

	get_surface_override_material(0).set("shader_parameter/displace", _displace_texture);

var i = 0

func _process(_delta: float) -> void:
	
	if i % 30 != 29:
		i += 1
		return
	else:
		i = 0
	
	# update texture (TODO based on raycast nodes, one generated per pixel on ready)
	_displace.fill(Color.BLACK)
	
	var u := randi_range(0, w - 1)
	var v := randi_range(0, h - 1)
	
	_displace.set_pixel(u, v, Color.RED)
	
	$Test.position = uv_to_vec3((u + 0.5) / w, (v + 0.5) / h)
	
	# update material
	_displace_texture.update(_displace)
