extends RigidBody3D

var meow_timer: float
var active := true

var material: Material

var mesh_base_y: float

@export var hold_distance := 1.0

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
	
	mesh_base_y = $Mesh.position.y
	
	# duplicate our materials so we can modify them
	material = $Mesh.get_active_material(0).duplicate()
	$Mesh.set_surface_override_material(0, material)

func set_active(value : bool):
	
	_set_activity_state(ActivityState.ROLLING)
	
	active = value
	freeze = not value
	$Collider.disabled = not value
	
	material.set_shader_parameter("transparent", not value)

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
	
	$TextAnchor.global_rotation = Vector3.ZERO
	$TextAnchor/Text.look_at(get_viewport().get_camera_3d().global_position, Vector3.UP, true)
	
	# activity
	if active:
		
		meow_timer -= delta
		
		if activity_state == ActivityState.ROLLING:
			
			if linear_velocity.length() < 1.0 and position_onto_ground(delta):
				_set_activity_state(ActivityState.IDLING)
			
		else:
			
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
					
					position_onto_ground(delta)
				
				ActivityState.WALKING_STRAIGHT:
					
					$Mesh.position.y = mesh_base_y + abs(sin(Time.get_ticks_msec() * 0.01) * 0.05)
					
					global_position += global_basis.z * MAX_SPEED * delta
					
					position_onto_ground(delta)
				
				ActivityState.WALKING_LEFT:
					
					$Mesh.position.y = mesh_base_y + abs(sin(Time.get_ticks_msec() * 0.01) * 0.05)
					
					global_position += global_basis.z * MAX_SPEED * delta
					global_rotation -= global_basis.y * MAX_TURN_SPEED * delta
					
					position_onto_ground(delta)
				
				ActivityState.WALKING_RIGHT:
					
					$Mesh.position.y = mesh_base_y + abs(sin(Time.get_ticks_msec() * 0.01) * 0.05)
					
					global_position += global_basis.z * MAX_SPEED * delta
					global_rotation += global_basis.y * MAX_TURN_SPEED * delta
					
					position_onto_ground(delta)
	
	# idle animation
	var f := sin(Time.get_ticks_msec() * 0.01) * 0.05
	$Mesh.scale.x = 1.0 - f
	$Mesh.scale.y = 1.0 + f
	$Mesh.scale.z = 1.0 - f
	$Mesh.rotation.z = sin(Time.get_ticks_msec() * 0.005 - PI / 4) * 0.05

func position_onto_ground(delta: float) -> bool: # returns true if succeeded
	
	$GroundingRay.global_rotation = Vector3.ZERO
	$GroundingRay.force_raycast_update()
	
	if $GroundingRay.is_colliding():
		
		# place onto surface
		global_position = $GroundingRay.get_collision_point() + Vector3(0.0, $Collider.shape.radius, 0.0)
		
		# align w/ surface normal
		var prev = $Mesh.global_basis.get_rotation_quaternion()
		$Mesh.look_at($Mesh.global_position + $GroundingRay.get_collision_normal().cross(global_basis.x), $GroundingRay.get_collision_normal())
		$Mesh.global_basis = Basis(lerp(prev, $Mesh.global_basis.get_rotation_quaternion(), 10.0 * delta))
		
		return true
	
	# failed to ground, must be in the air!
	_set_activity_state(ActivityState.ROLLING)
	apply_central_impulse(global_basis.z)
	
	return false
