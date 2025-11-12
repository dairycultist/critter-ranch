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

# growth
var curr_scale : float
var prev_scale : float
var scale_lerp : float

func _ready() -> void:
	
	curr_scale = 1 # start at x1 scale
	scale_lerp = -1 # no scaling on ready pls
	
	_set_activity_state(ActivityState.IDLING, 0.0)
	
	# duplicate our material so we can modify it
	material = $Mesh.get_child(0).get_active_material(0).duplicate()
	
	# assign the material to every submesh of our mesh
	for child in $Mesh.get_children():
		child.set_surface_override_material(0, material)
	
	# log every scaled child's base position (for position scaling)
	for child in get_children():
		if child.get("scale"):
			child.set_meta("base_position", child.position)

func grow():
	prev_scale = curr_scale
	curr_scale = prev_scale * 1.2
	scale_lerp = 0.0

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
	
	if Input.is_action_just_pressed("ui_accept"):
		grow()
	
	# growing (have to both scale AND reposition children, since position scales too)
	if scale_lerp >= 0.0 and scale_lerp < 1.0:
		
		var fac = lerp(prev_scale, curr_scale, clampf(scale_lerp, 0, 1))
		scale_lerp += delta
		
		for child in get_children():
			if child.get("scale"):
				child.scale = Vector3(fac, fac, fac)
				child.position = child.get_meta("base_position") * Vector3(fac, fac, fac)
		
	elif scale_lerp >= 1.0:
		
		scale_lerp = -1
		
		for child in get_children():
			if child.get("scale"):
				child.scale = Vector3(curr_scale, curr_scale, curr_scale)
				child.position = child.get_meta("base_position") * Vector3(curr_scale, curr_scale, curr_scale)
	
	# activity
	if active:
		
		meow_timer -= delta
		
		# probably grounded
		if linear_velocity.y < 0 and linear_velocity.y > -0.01:
			
			# random meowing/state changes
			if (meow_timer < 0):
			
				$MeowSound.volume_linear = randf() * 0.1 + 0.1
				$MeowSound.pitch_scale   = randf() * 0.2 + 0.8
				$MeowSound.play()
				
				_set_activity_state(ActivityState.get(ActivityState.keys().pick_random()), 0.5)
		
			# linear drag (angular drag is handled by rigidbody's angular damp)
			apply_central_force(-linear_velocity * 500 * delta)
			
			var angle_to_upright = acos(global_basis.y.dot(Vector3(0, 1, 0)))
			
			if angle_to_upright > 0.3:
				
				# default to idle animation if doesn't have footing
				if activity_state != ActivityState.IDLING:
					_set_activity_state(ActivityState.IDLING, 0.5)
				
				# attempt to hop upright
				if linear_velocity.length() < 0.02 and angular_velocity.length() < 0.02:
				
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
