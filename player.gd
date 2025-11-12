extends CharacterBody3D

var grab_x_fling := 0.0
var grab_y_fling := 0.0
var grabbed_critter : Node3D

var camera_pitch := 0.0

@export_group("Movement")
@export var mouse_sensitivity := 0.3

@export var drag := 15.0
@export var accel := 160.0
@export var jump_speed := 8.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	
	# kill floor
	if (position.y < -10):
		position = Vector3(0, 10, 0)
		velocity = Vector3.ZERO
		
	# grabbies! uppies!
	if (Input.is_action_just_pressed("fire")):
		
		if grabbed_critter:
			
			# letting go critters
			grabbed_critter.reparent(get_tree().current_scene)
			grabbed_critter.set_active(true)
			
			# fling!
			grabbed_critter.linear_velocity = 40 * (Vector3(0, grab_y_fling, 0) + basis.x * grab_x_fling)
			
			grabbed_critter = null
		
		else:
			
			# picking up critters
			var ray_result = get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(
					$Camera3D.global_position,
					$Camera3D.global_position + $Camera3D.global_basis.z * -10
				)
			)
			
			if ray_result and ray_result.collider.has_method("set_active"):
				
				grabbed_critter = ray_result.collider
				
				grabbed_critter.set_active(false)
				grabbed_critter.reparent(self)
				grabbed_critter.position = Vector3(0, 1, -grabbed_critter.get_hold_distance())
				grabbed_critter.rotation = Vector3.ZERO
	
	if grabbed_critter:
		grabbed_critter.rotation.z = lerp(grabbed_critter.rotation.z, grab_x_fling * 4, delta * 10)
		grabbed_critter.rotation.x = lerp(grabbed_critter.rotation.x, grab_y_fling * -4, delta * 10)
	grab_x_fling = lerp(grab_x_fling, 0.0, delta * 10)
	grab_y_fling = lerp(grab_y_fling, 0.0, delta * 10)
	
	# movement
	var input_dir := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	velocity += get_gravity() * delta
	
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump_speed
	
	if direction:
		velocity.x += direction.x * accel * delta
		velocity.z += direction.z * accel * delta
	
	velocity.x = lerp(velocity.x, 0.0, delta * drag)
	velocity.z = lerp(velocity.z, 0.0, delta * drag)
	
	move_and_slide()

func _input(event):
	
	if event.is_action_pressed("pause"):
		
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event is InputEventMouseMotion:
		
		rotation.y += deg_to_rad(-event.relative.x * mouse_sensitivity)
		
		camera_pitch = clampf(camera_pitch - event.relative.y * mouse_sensitivity, -90, 90)
		
		$Camera3D.rotation.x = deg_to_rad(camera_pitch)
		grab_x_fling = deg_to_rad(event.relative.x * mouse_sensitivity)
		grab_y_fling = deg_to_rad(-event.relative.y * mouse_sensitivity)
