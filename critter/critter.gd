extends RigidBody3D

@export var hop_speed := 7.0

var meow_timer = 3.0
var active := true

func set_active(value : bool):
	
	active = value
	freeze = not value
	$CollisionFeet.disabled = not value
	$CollisionBody.disabled = not value
	$CollisionHead.disabled = not value

func _process(delta: float) -> void:
	
	# random meowing
	meow_timer -= delta
	
	if (meow_timer < 0):
		meow_timer = randi_range(3, 12)
		$MeowSound.volume_linear = randf() * 0.5 + 0.5
		$MeowSound.pitch_scale   = randf() * 0.2 + 0.8
		$MeowSound.play()
	
	# TODO walking around/idling in one place
	
	# self-righting
	if active and linear_velocity.length() < 0.01 and angular_velocity.length() < 0.01:
		_right_self_if_necessary()

func _right_self_if_necessary():
	
	var angle_to_upright = acos(basis.y.dot(Vector3(0, 1, 0)))
		
	if angle_to_upright > 0.1:
		
		# hop upright
		var axis_to_upright = basis.y.cross(Vector3(0, 1, 0)).normalized()
		
		var righting_rot = Quaternion(axis_to_upright, angle_to_upright).get_euler(EULER_ORDER_XYZ)
		
		apply_torque_impulse(righting_rot * hop_speed / 40.0) # idk
		apply_central_impulse(Vector3(0, hop_speed, 0))
