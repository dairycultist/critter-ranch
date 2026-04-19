extends RigidBody3D

var meow_timer : float
var active := true

var material : Material

enum ActivityState {
	ROLLING,
	IDLING,
	WALKING_STRAIGHT,
	WALKING_LEFT,
	WALKING_RIGHT
}
var activity_state : ActivityState

func _ready() -> void:
	
	_set_activity_state(ActivityState.ROLLING)
	
	# duplicate our materials so we can modify them
	material = $Mesh.get_active_material(0).duplicate()

func get_hold_distance():
	return 1.0

func set_active(value : bool):
	
	active = value
	freeze = not value
	$Collider.disabled = not value
	
	material.set_shader_parameter("transparent", not value)
	
	if value:
		_set_activity_state(ActivityState.ROLLING)
	else:
		_set_activity_state(ActivityState.IDLING)

func _set_activity_state(value : ActivityState):
	
	meow_timer = randi_range(3, 12)
	
	activity_state = value
	
	# physics
	if activity_state == ActivityState.ROLLING:
		freeze = false
	else:
		freeze = true
		rotation.x = 0
		rotation.z = 0

func _process(delta: float) -> void:
	
	# activity
	if active:
		
		meow_timer -= delta
		
		# probably grounded
		if abs(linear_velocity.y) < 0.1:
			
			# random meowing/state changes
			if (meow_timer < 0):
			
				$MeowSound.volume_linear = randf() * 0.1 + 0.1
				$MeowSound.pitch_scale   = randf() * 0.2 + 0.8
				$MeowSound.play()
				
				_set_activity_state([
					ActivityState.IDLING,
					ActivityState.WALKING_STRAIGHT,
					ActivityState.WALKING_LEFT,
					ActivityState.WALKING_RIGHT
				].pick_random())
			
			# movement behaviour, walking around, idling in one place...
			const MAX_SPEED = 1.0
			const MAX_TURN_SPEED = 0.3
			
			match activity_state:
				
				ActivityState.ROLLING:
					pass
				
				ActivityState.IDLING:
					pass
				
				ActivityState.WALKING_STRAIGHT:
					
					global_position += global_basis.z * MAX_SPEED * delta
				
				ActivityState.WALKING_LEFT:
					
					global_position += global_basis.z * MAX_SPEED * delta
					global_rotation -= global_basis.y * MAX_TURN_SPEED * delta
				
				ActivityState.WALKING_RIGHT:
					
					global_position += global_basis.z * MAX_SPEED * delta
					global_rotation += global_basis.y * MAX_TURN_SPEED * delta
