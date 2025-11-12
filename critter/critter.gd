extends RigidBody3D

@export var hop_speed_linear := 4.0
@export var hop_speed_angular := 0.1

@export var hold_distance := 1.0

var meow_timer : float
var active := true

var material : Material

enum ActivityState {
	IDLING,
	RESTING, # same as idling but with a different animation
	WALKING_STRAIGHT,
	WALKING_LEFT,
	WALKING_RIGHT
}
var activity_state : ActivityState

func _ready() -> void:
	
	_set_activity_state(ActivityState.IDLING, 0.0)
	
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
	
	_set_activity_state(ActivityState.IDLING, 0.0)

func _set_activity_state(value : ActivityState, transition_duration : float):
	
	meow_timer = randi_range(3, 12)
	
	activity_state = value
		
	if $AnimationPlayer:
		if activity_state == ActivityState.IDLING or activity_state == ActivityState.RESTING:
			$AnimationPlayer.play("idle", transition_duration)
		else:
			$AnimationPlayer.play("walk", transition_duration)

func _process(delta: float) -> void:
	
	# random meowing
	if active:
		meow_timer -= delta
	
	if (meow_timer < 0):
		
		$MeowSound.volume_linear = randf() * 0.1 + 0.1
		$MeowSound.pitch_scale   = randf() * 0.2 + 0.8
		$MeowSound.play()
		
		_set_activity_state(ActivityState.get(ActivityState.keys().pick_random()), 0.5)
	
	# activity (probably grounded)
	if active and linear_velocity.y < 0 and linear_velocity.y > -0.01:
		
		# linear drag (angular drag is handled by rigidbody's angular damp)
		apply_central_force(-linear_velocity * 500 * delta)
		
		var angle_to_upright = acos(global_basis.y.dot(Vector3(0, 1, 0)))
		
		if angle_to_upright > 0.3:
			
			# attempt to hop upright
			if linear_velocity.length() < 0.01 and angular_velocity.length() < 0.01:
			
				var axis_to_upright = global_basis.y.cross(Vector3(0, 1, 0)).normalized()
				
				var righting_rot = Quaternion(axis_to_upright, angle_to_upright).get_euler(EULER_ORDER_XYZ)
				
				apply_torque_impulse(righting_rot * hop_speed_angular)
				apply_central_impulse(Vector3(0, hop_speed_linear, 0))
		
		else:
				
			# movement behaviour, walking around, idling in one place...
			
			const MAX_SPEED = 1.0
			const MAX_TURN_SPEED = 0.3
			
			match activity_state:
				
				ActivityState.WALKING_STRAIGHT:
					
					if (linear_velocity.length() < MAX_SPEED):
						apply_central_force(global_basis.z * 500 * delta)
				
				ActivityState.WALKING_LEFT:
					
					if (linear_velocity.length() < MAX_SPEED):
						apply_central_force(global_basis.z * 500 * delta)
					
					if (angular_velocity.y > -MAX_TURN_SPEED):
						apply_torque(Vector3(0, -50 * delta, 0))
				
				ActivityState.WALKING_RIGHT:
					
					if (linear_velocity.length() < MAX_SPEED):
						apply_central_force(global_basis.z * 500 * delta)
					
					if (angular_velocity.y < MAX_TURN_SPEED):
						apply_torque(Vector3(0, 50 * delta, 0))
