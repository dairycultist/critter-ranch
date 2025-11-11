extends RigidBody3D

var hop_timer = 5.0

var prev_speed := 0.0

func _process(delta: float) -> void:
	
	# sounds based on speed change
	var curr_speed := linear_velocity.length()
	
	if (curr_speed < 0.01 and prev_speed > 0.01):
		
		var volume := 1.0 - 1.0 / (prev_speed * 0.1 + 1.0) # map to [0,1]
		
		$BumpSound.volume_linear = volume
		$BumpSound.pitch_scale = volume / 10 + 0.9
		$BumpSound.play()
	
	prev_speed = curr_speed
	
	# hopping
	hop_timer -= delta
	
	if (hop_timer < 0):
		hop_timer = 5.0
		hop()

func hop():
	
	var angle_to_upright = acos(basis.y.dot(Vector3(0, 1, 0)))
		
	if (angle_to_upright < 0.001):
		
		# hop forward
		apply_central_impulse(Vector3(0, 7, 0) + basis.z * 4)
		
	else:
		
		# hop upright
		var axis_to_upright = basis.y.cross(Vector3(0, 1, 0)).normalized()
		
		var righting_rot = Quaternion(axis_to_upright, angle_to_upright).get_euler(EULER_ORDER_XYZ)
		
		apply_torque_impulse(righting_rot)
		apply_central_impulse(Vector3(0, 7, 0))
