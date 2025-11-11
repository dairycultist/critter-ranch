extends RigidBody3D

var timer = 5.0

func _process(delta: float) -> void:
	
	timer -= delta
	
	if (timer < 0):
		apply_central_impulse(Vector3(0, 7, 0))
		apply_torque_impulse(Vector3(-rotation.x, 0, -rotation.z))
		timer = 5.0
