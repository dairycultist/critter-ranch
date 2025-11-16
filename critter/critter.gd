extends RigidBody3D

@export_group("Visual")

enum Variation {
	GLORBO,
	ANGEL
}
@export var _VARIATION := Variation.GLORBO

var variation_data = [
	["head mesh", "torso mesh", preload("res://critter/variations/glorbo_tex.png")],
	["head mesh", "torso mesh", preload("res://critter/variations/angel_tex.png")]
]

@export var _HOLD_DISTANCE := 1.0
@export var _START_SCALE := 1.0

@export_group("Hopping")
@export var _HOP_SPEED_LINEAR := 4.0
@export var _HOP_SPEED_ANGULAR := 0.1

var meow_timer : float
var active := true

var material : Material

enum ActivityState {
	IDLING,
	RESTING, # same as idling but with a different animation
	WALKING_STRAIGHT,
	WALKING_LEFT,
	WALKING_RIGHT,
	WOBBLE
}
var activity_state : ActivityState

var animation : AnimationPlayer

# growth
var curr_scale : float
var prev_scale : float
var scale_lerp : float
@export var _GROW_SPEED := 0.75

func _ready() -> void:
	
	animation = $Animated/AnimationPlayer
	
	_set_activity_state(ActivityState.IDLING, 0.0)
	
	# log every scaled child's base position (for position scaling)
	for child in get_children():
		if child.get("scale"):
			child.set_meta("base_position", child.position)
	
	# set initial scale
	curr_scale = _START_SCALE
	scale_lerp = -1 # no growing on ready
	set_growth_scale(curr_scale)
	
	# duplicate our material so we can modify it
	material = $Animated/Mesh.get_child(0).get_active_material(0).duplicate()
	
	material.set("shader_parameter/tex", variation_data[_VARIATION][2]);
	
	# assign the material to every submesh of our mesh
	for child in $Animated/Mesh.get_children():
		
		child.set_surface_override_material(0, material)
		
		for childs_child in child.get_children():
			childs_child.set_surface_override_material(0, material)

func get_hold_distance():
	return _HOLD_DISTANCE * curr_scale

func grow():
	prev_scale = curr_scale
	curr_scale = prev_scale + 0.2
	scale_lerp = 0.0

func set_growth_scale(fac):
	
	for child in get_children():
		if child.get("scale"):
			child.scale = Vector3(fac, fac, fac)
			child.position = child.get_meta("base_position") * Vector3(fac, fac, fac)

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
		
	if animation:
		if activity_state == ActivityState.IDLING or activity_state == ActivityState.RESTING:
			animation.play("idle", transition_duration)
		elif activity_state == ActivityState.WOBBLE:
			animation.play("wobble", transition_duration)
		else:
			animation.play("walk", transition_duration)

func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("ui_accept"):
		grow()
	
	# wobble animation state immediately switches to IDLING upon completion
	if activity_state == ActivityState.WOBBLE and animation and not animation.is_playing():
		_set_activity_state(ActivityState.IDLING, 0.0)
	
	# growing (have to both scale AND reposition children, since position scales too)
	if scale_lerp >= 0.0 and scale_lerp < 1.0:
		
		var fac = lerp(prev_scale, curr_scale, clampf(scale_lerp, 0, 1))
		scale_lerp += delta * _GROW_SPEED
		
		set_growth_scale(fac)
		
	elif scale_lerp >= 1.0:
		
		scale_lerp = -1
		
		set_growth_scale(curr_scale)
		
		_set_activity_state(ActivityState.WOBBLE, 0)
	
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
				
				# TODO shouldn't pick WOBBLE
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
					
					apply_torque_impulse(righting_rot * _HOP_SPEED_ANGULAR * curr_scale)
					apply_central_impulse(Vector3(0, _HOP_SPEED_LINEAR, 0))
			
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
