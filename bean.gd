extends RigidBody3D

var timer = 5.0

func _process(delta: float) -> void:
	
	timer -= delta
	
	if (timer < 0):
		
		var rotation_axis = basis.y.cross(Vector3(0, 1, 0)).normalized()
	
		var rotation_angle = acos(basis.y.dot(Vector3(0, 1, 0)))
		
		var righting_rot = Quaternion(rotation_axis, rotation_angle).get_euler(EULER_ORDER_XYZ)
		
		apply_torque_impulse(righting_rot)
		apply_central_impulse(Vector3(0, 7, 0))
		
		timer = 5.0
