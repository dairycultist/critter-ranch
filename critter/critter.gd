extends RigidBody3D

@export var hop_speed_linear := 4.0
@export var hop_speed_angular := 0.1

@export var hold_distance := 1.0

var meow_timer := 3.0
var active := true

var material : Material

func _ready() -> void:
	
	# duplicate our material so we can modify it
	material = $Mesh.get_child(0).get_active_material(0).duplicate()
	
	# assign the material to every submesh of our mesh
	for child in $Mesh.get_children():
		
		child.set_surface_override_material(0, material)

func set_active(value : bool):
	
	active = value
	freeze = not value
	$CollisionFeet.disabled = not value
	$CollisionBody.disabled = not value
	$CollisionHead.disabled = not value
	material.set_shader_parameter("transparent", not value)

func _process(delta: float) -> void:
	
	# random meowing
	meow_timer -= delta
	
	if (meow_timer < 0):
		meow_timer = randi_range(3, 12)
		$MeowSound.volume_linear = randf() * 0.1 + 0.1
		$MeowSound.pitch_scale   = randf() * 0.2 + 0.8
		$MeowSound.play()
	
	# TODO walking around/idling in one place
	
	# self-righting
	if active and linear_velocity.length() < 0.01 and angular_velocity.length() < 0.01:
		_right_self_if_necessary()

func _right_self_if_necessary():
	
	var angle_to_upright = acos(global_basis.y.dot(Vector3(0, 1, 0)))
		
	if angle_to_upright > 0.3:
		
		# hop upright
		var axis_to_upright = global_basis.y.cross(Vector3(0, 1, 0)).normalized()
		
		var righting_rot = Quaternion(axis_to_upright, angle_to_upright).get_euler(EULER_ORDER_XYZ)
		
		apply_torque_impulse(righting_rot * hop_speed_angular)
		apply_central_impulse(Vector3(0, hop_speed_linear, 0))
