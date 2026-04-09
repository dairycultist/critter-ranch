extends RigidBody3D

@export_group("Visual")

enum Breed {
	GLORBO,
	ANGEL
}

@export var _BREED := Breed.GLORBO

var breed_data = [
	[ # glorbo
		null,
		null,
		preload("res://critter/breeds/glorbo_tex.png")
	],
	[ # angel
		preload("res://critter/breeds/angel_hat.blend"),
		null,
		preload("res://critter/breeds/angel_tex.png")
	]
]

@export var _HOLD_DISTANCE := 1.0
@export var _START_SCALE := 1.0

var meow_timer : float
var active := true

var material : Material

enum ActivityState {
	ROLLING,
	IDLING,
	RESTING, # same as idling but with a different animation
	WALKING_STRAIGHT,
	WALKING_LEFT,
	WALKING_RIGHT
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
	
	_set_activity_state(ActivityState.ROLLING, 0.0)
	
	# log every scaled child's base position (for position scaling)
	for child in get_children():
		if child.get("scale"):
			child.set_meta("base_position", child.position)
	
	# set initial scale
	curr_scale = _START_SCALE
	scale_lerp = -1 # no growing on ready
	set_growth_scale(curr_scale)
	
	# add hat and coat meshes
	if breed_data[_BREED][0]:
		$Animated/Mesh/Head.add_child(breed_data[_BREED][0].instantiate())
	
	if breed_data[_BREED][1]:
		$Animated/Mesh.add_child(breed_data[_BREED][1].instantiate())
	
	# duplicate our materials so we can modify them
	material = $Animated/Mesh.get_child(0).get_active_material(0).duplicate()
	
	material.set("shader_parameter/tex", breed_data[_BREED][2]);
	
	$Body.material.set("shader_parameter/tex", breed_data[_BREED][2]);
	
	# assign the material to every submesh of our mesh
	set_child_material_recursive($Animated/Mesh, material)

func set_child_material_recursive(node, mat):
	
	for child in node.get_children():
		
		if child.has_method("set_surface_override_material"):
			child.set_surface_override_material(0, mat)
		
		set_child_material_recursive(child, mat)

func get_hold_distance():
	return _HOLD_DISTANCE * curr_scale

func grow():
	
	_set_activity_state(ActivityState.IDLING, 0.5)
	prev_scale = curr_scale
	curr_scale = prev_scale + 0.2
	scale_lerp = 0.0
	$GrowthSound.play()

func set_growth_scale(fac):
	
	for child in get_children():
		if child.get("scale"):
			child.scale = Vector3(fac, fac, fac)
			child.position = child.get_meta("base_position") * Vector3(fac, fac, fac)

func set_active(value : bool):
	
	# TODO instead of disabling rigidbody and locking the critter in front of the
	# camera, keep the rigidbody and just spring the critter to the camera
	
	active = value
	freeze = not value
	$Collider.disabled = not value
	
	material.set_shader_parameter("transparent", not value)
	$Body.material.set_shader_parameter("transparent", not value)
	
	if value:
		_set_activity_state(ActivityState.ROLLING, 0.0)
	else:
		_set_activity_state(ActivityState.IDLING, 0.0)

func _set_activity_state(value : ActivityState, transition_duration : float):
	
	meow_timer = randi_range(3, 12)
	
	activity_state = value
	
	# physics
	if activity_state == ActivityState.ROLLING:
		freeze = false
	else:
		freeze = true
		rotation.x = 0
		rotation.z = 0
	
	# animation
	if activity_state == ActivityState.IDLING or activity_state == ActivityState.RESTING:
		animation.play("idle", transition_duration)
	else:
		animation.play("walk", transition_duration)

func _process(delta: float) -> void:
	
	if scale_lerp >= 0.0 and scale_lerp < 1.0:
		
		# in process of growing (have to both scale AND reposition children,
		# since position doesn't scale by default)
		var fac = lerp(prev_scale, curr_scale, clampf(scale_lerp, 0, 1))
		scale_lerp += delta * _GROW_SPEED
		set_growth_scale(fac)
		
	elif scale_lerp >= 1.0:
		
		# finish growing
		scale_lerp = -1
		set_growth_scale(curr_scale)
	
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
					ActivityState.RESTING,
					ActivityState.WALKING_STRAIGHT,
					ActivityState.WALKING_LEFT,
					ActivityState.WALKING_RIGHT
				].pick_random(), 0.5)
			
			# movement behaviour, walking around, idling in one place...
			const MAX_SPEED = 1.0
			const MAX_TURN_SPEED = 0.3
			
			match activity_state:
				
				ActivityState.ROLLING:
					pass
				
				ActivityState.IDLING:
					pass
					
				ActivityState.RESTING:
					pass
				
				ActivityState.WALKING_STRAIGHT:
					
					global_position += global_basis.z * MAX_SPEED * delta
				
				ActivityState.WALKING_LEFT:
					
					global_position += global_basis.z * MAX_SPEED * delta
					global_rotation -= global_basis.y * MAX_TURN_SPEED * delta
				
				ActivityState.WALKING_RIGHT:
					
					global_position += global_basis.z * MAX_SPEED * delta
					global_rotation += global_basis.y * MAX_TURN_SPEED * delta
