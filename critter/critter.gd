extends RigidBody3D

@export var hop_speed := 7.0

var hop_timer = 5.0
var meow_timer = 3.0

func set_active(value : bool):
	
	freeze = not value
	$CollisionFeet.disabled = not value
	$CollisionBody.disabled = not value
	$CollisionHead.disabled = not value
	hop_timer = 5.0

func _process(delta: float) -> void:
	
	# random meowing
	meow_timer -= delta
	
	if (meow_timer < 0):
		meow_timer = randi_range(3, 12)
		$MeowSound.volume_linear = randf() * 0.5 + 0.5
		$MeowSound.pitch_scale = randf() * 0.1 + 0.9
		$MeowSound.play()
	
	# hopping
	if freeze == false:
		hop_timer -= delta
	
	if (hop_timer < 0):
		hop_timer = 5.0
		_hop()

func _hop():
	
	var angle_to_upright = acos(basis.y.dot(Vector3(0, 1, 0)))
		
	if angle_to_upright < 0.1:
		
		# hop forward
		apply_central_impulse(Vector3(0, hop_speed, 0) + basis.z * hop_speed / 2)
		
	else:
		
		# hop upright
		var axis_to_upright = basis.y.cross(Vector3(0, 1, 0)).normalized()
		
		var righting_rot = Quaternion(axis_to_upright, angle_to_upright).get_euler(EULER_ORDER_XYZ)
		
		apply_torque_impulse(righting_rot * hop_speed / 40.0) # idk
		apply_central_impulse(Vector3(0, hop_speed, 0))
