extends MeshInstance3D

@export var w: int = 4
@export var h: int = 4
@export var mesh_radius: float = 1.0
@export var frames_per_mesh_update: int = 4
var i := 0

var _displace_a: Image
var _displace_b: Image # _displace_a but blurred
var _displace_texture: ImageTexture

# polar coordinate conversion
static func uv_to_vec3(u: float, v: float) -> Vector3:
	
	u = u * TAU
	v = (v - 0.5) * PI
	
	# +z direction is u=0
	return Vector3(sin(u) * cos(v), -sin(v), cos(u) * cos(v))

func _ready() -> void:
	
	_displace_a = Image.create_empty(w, h, false, Image.FORMAT_R8)
	_displace_a.fill(Color.WHITE)
	
	_displace_b = Image.create_empty(w, h, false, Image.FORMAT_R8)
	_displace_b.fill(Color.WHITE)

	_displace_texture = ImageTexture.create_from_image(_displace_b)

	var mat: Material = get_surface_override_material(0).duplicate()

	set_surface_override_material(0, mat)
	mat.set("shader_parameter/displace", _displace_texture);

func _process(_delta: float) -> void:
	
	if i > 1:
		i -= 1
		return
	else:
		i = frames_per_mesh_update
	
	# update texture based on raycast (one per pixel)
	_displace_a.fill(Color.WHITE)
	
	for u in range(w):
		for v in range(h):
	
			var query = PhysicsRayQueryParameters3D.create(
				global_position,
				# accounts for pos, rot, and scale!
				to_global(uv_to_vec3((u + 0.5) / w, (v + 0.5) / h) * mesh_radius)
			)
	
			var result = get_world_3d().direct_space_state.intersect_ray(query)
			
			if result:
				_displace_a.set_pixel(u, v, Color(0.5 * global_position.distance_to(result.position) / (scale.x * mesh_radius), 0.0, 0.0, 0.0))
			else:
				_displace_a.set_pixel(u, v, Color(0.5, 0.0, 0.0, 0.0))
	
	# make neutral values near indented ones outdent
	for u in range(w):
		for v in range(h):
			
			var r := _displace_a.get_pixel(posmod(u, w), posmod(v, h)).r
			
			if r < 0.49:
				continue
			
			var r_new = 1.0 - min(
				_displace_a.get_pixel(posmod(u + 1, w), clampi(v + 1, 0, h - 1)).r, # clamp v because we don't wrap that way
				_displace_a.get_pixel(posmod(u - 1, w), clampi(v + 1, 0, h - 1)).r,
				_displace_a.get_pixel(posmod(u + 1, w), clampi(v - 1, 0, h - 1)).r,
				_displace_a.get_pixel(posmod(u - 1, w), clampi(v - 1, 0, h - 1)).r
			)
			
			_displace_a.set_pixel(u, v, Color(r_new, 0.0, 0.0, 0.0))
	
	# blur such that only non-indented values change
	for u in range(w):
		for v in range(h):
			
			var r := _displace_a.get_pixel(posmod(u, w), posmod(v, h)).r
			
			var r_new := r if r < 0.49 else (r +
				_displace_a.get_pixel(posmod(u + 1, w), clampi(v + 1, 0, h - 1)).r +
				_displace_a.get_pixel(posmod(u - 1, w), clampi(v + 1, 0, h - 1)).r +
				_displace_a.get_pixel(posmod(u + 1, w), clampi(v - 1, 0, h - 1)).r +
				_displace_a.get_pixel(posmod(u - 1, w), clampi(v - 1, 0, h - 1)).r) / 5.0
			
			_displace_b.set_pixel(u, v, Color(r_new, 0.0, 0.0, 0.0))
	
	# update material
	_displace_texture.update(_displace_b)
