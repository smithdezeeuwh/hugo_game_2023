extends CharacterBody3D


const WALK_SPEED = 5.0
const SPRINT_MULTIPLIER = 2.0
const CROUCH_MULTIPLIER: float = 0.5

const JUMP_VELOCITY: float = 7.5
const GRAVITY: float = 45.0
const AIR_ACCELERATION: float = 10.0
const REGULAR_ACCELERATION: float = 20.0

const CROUCH_TRANSITION_SPEED: float = 0.1
const COLLIDER_REGULAR_HEIGHT: float = 1.8
const COLLIDER_CROUCH_HEIGHT: float = 0.9
const HEAD_CROUCH_HEIGHT := 0.9
const HEAD_STANDING_HEIGHT := 1.8

const MOUSE_SENSITIVITY: float = 0.002
const CAMERA_UPPER_CLAMP: float = 90.0 # These two are later converted to radians.
const CAMERA_LOWER_CLAMP: float = -90.0


enum MovementStates{ON_GROUND, IN_AIR}

const reach_ray_length = 5

# Camera.
var mouse_rotation := Vector3.ZERO
var camera_upper_clamp_rad: float # These two are the ones used to clamp the vertical look direction.
var camera_lower_clamp_rad: float # They get their values in radians in _ready().
@export var camera_position_offset := Vector3(0, 1.8, 0)
var camera_effect_offset := Vector3.ZERO
var camera_FOV: float = 80
var camera_recoil_x: float = 0 
var camera_recoil_y: float = 0 
var camera_FOV_clamp: int = 100

#@onready var tween := create_tween()

# Movement.
var movement := Vector3() # Final movement direction and magnitude for one tick.
var current_movement_state = MovementStates.IN_AIR
var horizontal_velocity := Vector3.ZERO
var original_horizontal_velocity := Vector3() # Used for preserving momentum when transitioning between different movement states.
var direction := Vector3.ZERO
var gravity_vector := Vector3.ZERO
var current_collider_height: float = 1.8 # Used for shrinking the collider when crouching.
var CROUCH_SLIDE_MULTIPLIER: float = 1.2

# Movement flags.
var is_grounded: bool = false
var can_jump: bool = false
var is_momentum_preserved: bool = false
var is_head_bonked: bool = false
var offset_velocity := Vector3.ZERO
var ready_to_crouch_slide: bool = false
var is_sprinting: bool 
var is_crouchsliding: bool 


@onready var camera: Camera3D = $Camera3D
@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var ui = $PlayerUI
@onready var item_manager = $Camera3D/Hands
@onready var raycast = $Camera3D/RayCast3D

func _ready() -> void:
	
	camera.current = true
	
	EventBus.projectile_fired.connect(_on_projectile_fired) # For recoil and stuff.
	#EventBus.player_reloaded.connect(_on_player_reloaded) # For updating the ui after reloading.
	EventBus.update_player_ui.connect(_on_update_player_ui) # For updating the ui after reloading.
	
	# Convert these two to radians because Godot likes it, I suppose.
	camera_upper_clamp_rad = deg_to_rad(CAMERA_UPPER_CLAMP)
	camera_lower_clamp_rad = deg_to_rad(CAMERA_LOWER_CLAMP)
	
	# Keep the mouse positioned at screen centre.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	process_camera_position()
	
	if item_manager.is_ads():
		#camera_FOV = lerp(camera_FOV, 60, 0.5 *  _delta)
		print("befoire " + str(camera_FOV))
		camera_FOV = lerp(camera_FOV, 50.0, delta * 2)
	if is_sprinting == true:
		camera_FOV = lerp(camera_FOV, 100.0, delta * 2)
	if is_crouchsliding == true :
		pass
	else:
		camera_FOV = lerp(camera_FOV, 90.0, delta * 2)
	
	print("after " + str(camera_FOV))
	camera.set_fov(camera_FOV)
		
	camera_FOV = clamp(camera_FOV, 0, 100)
	#print("cap" + str(tween.is_running()))

func _input(event: InputEvent) -> void:
	# Only look around if the mouse is invisible.
	if event is InputEventMouseMotion:
		var relative_mouse_motion: Vector2 = event.relative
		process_camera_rotation(relative_mouse_motion)
		
	
	# Which way we are going to move.
	direction = Vector3()
	
	# Forwards/backwards and left/right input and movement.
	# Direction is taken according to the camera y axis instead of the actual
	# body so that we don't get weird physics rotation stuff!
	direction += -global_transform.basis.x.rotated(Vector3(0, 1 ,0), camera.rotation.y) * (Input.get_action_strength("move_left") - Input.get_action_strength("move_right"))
	direction += -global_transform.basis.z.rotated(Vector3(0, 1, 0), camera.rotation.y) * (Input.get_action_strength("move_forwards") - Input.get_action_strength("move_backwards"))
	
	# Ensure we aren't faster when moving diagonally.
	direction = direction.normalized()
	
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					item_manager.next_item()
				MOUSE_BUTTON_WHEEL_DOWN:
					item_manager.previous_item()

func handle_input() -> void:
	# Items and stuff.
	if Input.is_action_pressed("fire"):
		item_manager.request_action("fire")
	if Input.is_action_just_released("fire"):
		item_manager.request_action("fire_stop")
	
	if Input.is_action_just_pressed("fire_2"):
		item_manager.request_action("fire_2")
	if Input.is_action_just_released("fire_2"):
		item_manager.request_action("fire_2_stop")
	
	if Input.is_action_just_pressed("drop_item"):
		item_manager.request_action("drop_item")
	
	if Input.is_action_just_pressed("reload"):
		item_manager.request_action("reload")
		
	if Input.is_action_just_pressed("primary"):
		item_manager.equip_primary()
		

	if Input.is_action_just_pressed("secondary"):
		item_manager.equip_secondary()
		
	if Input.is_action_just_pressed("melee"):
		item_manager.equip_melee()

		
	
func _physics_process(delta: float) -> void:
	item_manager.check_item_pickup(raycast)
	
	handle_input()
	
	check_movement_flags()
	handle_crouching()
	process_movement_state(delta)
	
	ui.update_speed(horizontal_velocity)

func check_movement_flags() -> void:
	if is_on_floor():
		current_movement_state = MovementStates.ON_GROUND
	else:
		current_movement_state = MovementStates.IN_AIR

func process_camera_position() -> void:
	camera.global_position = global_position + camera_position_offset + camera_effect_offset
	

func process_camera_rotation(relative_mouse_motion) -> void:
	# Horizontal mouse look.
	mouse_rotation.y -= relative_mouse_motion.x * MOUSE_SENSITIVITY
	# Vertical mouse look.
	mouse_rotation.x = clampf(mouse_rotation.x - (relative_mouse_motion.y * MOUSE_SENSITIVITY),
			camera_lower_clamp_rad,
			camera_upper_clamp_rad)
	
	# Rotate head independently of body.
	# This camera also determines the local direction of WASD.
	camera.rotation.x = mouse_rotation.x
	camera.rotation.y = mouse_rotation.y

func check_movement_state() -> void:
	if is_on_floor():
		current_movement_state = MovementStates.ON_GROUND
	else:
		current_movement_state = MovementStates.IN_AIR

func process_movement_state(delta) -> void:
	match current_movement_state:
		MovementStates.ON_GROUND:
			ground_move(delta)
		MovementStates.IN_AIR:
			air_move(delta)

func ground_move(delta: float) -> void:
	is_momentum_preserved = false
	
	# Stick to slopes and stuff.
	gravity_vector = -get_floor_normal()
	
	if Input.is_action_pressed("jump"):
		# TODO: reset momentum somehow
		jump()
	
	var sprinting = Input.is_action_pressed("sprint")
	var crouching = Input.is_action_pressed("crouch")
	
	if not crouchin_sliding():
		is_crouchsliding = false
		CROUCH_SLIDE_MULTIPLIER = 1.2
		#camera_FOV = 90
	
	if sprinting:
		horizontal_velocity = horizontal_velocity.lerp(
				direction * (WALK_SPEED * SPRINT_MULTIPLIER),
				REGULAR_ACCELERATION * delta) # TODO: is delta frame-independent?
		is_sprinting = true
		
		if crouchin_sliding():
			is_crouchsliding = true 
			horizontal_velocity *= CROUCH_SLIDE_MULTIPLIER
			if CROUCH_SLIDE_MULTIPLIER > 0:
				CROUCH_SLIDE_MULTIPLIER -= 0.005
				camera_FOV += 1
			
	else:
		is_sprinting = false
		horizontal_velocity = horizontal_velocity.lerp(
				direction * WALK_SPEED,
				REGULAR_ACCELERATION * delta)
	
	# Velocity vector calculated from horizontal direction and gravity.
	velocity.z = horizontal_velocity.z + gravity_vector.z
	velocity.x = horizontal_velocity.x + gravity_vector.x
	velocity.y = gravity_vector.y
	
	move_and_slide()

func wait(t):
	await get_tree().create_timer(t).timeout
	

#to reset to make sure you dont crouch to crouch sldie
func can_crouch_slide():
	if Input.is_action_pressed("crouch") and not Input.is_action_pressed("sprint"):
		ready_to_crouch_slide = false
		

func crouchin_sliding():
	if Input.is_action_pressed("crouch") and Input.is_action_pressed("sprint"):
		return true
#	var temp_var = false
#	if Input.is_action_pressed("sprint") and not Input.is_action_pressed("crouch"):
#		temp_var = ready_to_crouch_slide
#		if temp_var == ready_to_crouch_slide:
#			print("pass")
#			if Input.is_action_pressed("sprint") and Input.is_action_pressed("crouch"):
#				print("return true")
#				return true

func handle_crouching() -> void:
	
	# Change colliders when crouching TODO explain
	# Head movement is 
	if Input.is_action_pressed("crouch") or is_head_bonked:
		current_collider_height -= CROUCH_TRANSITION_SPEED
		#head.translation = head.translation.linear_interpolate(Vector3(0, 1.25, 0), CROUCH_TRANSITION_SPEED)
	else:
		current_collider_height += CROUCH_TRANSITION_SPEED
		#head.translation = head.translation.linear_interpolate(Vector3(0, 1.8, 0), CROUCH_TRANSITION_SPEED)
	
	# Crouch and regular height determine the shortest and highest we can stand, respectively.
	current_collider_height = clamp(current_collider_height, COLLIDER_CROUCH_HEIGHT, COLLIDER_REGULAR_HEIGHT)
	
	collider.shape.height = current_collider_height

func air_move(delta) -> void:
	gravity_vector += Vector3.DOWN * GRAVITY * (delta / 2) # Fall to the ground.
	
	# Makes the player slow down or speed up, depending on what they hit.
	var fr_fr = get_real_velocity()
	horizontal_velocity.x = fr_fr.x
	horizontal_velocity.z = fr_fr.z
	
	# Get the velocity over ground from when we jumped / became airborne.
	if not is_momentum_preserved:
		original_horizontal_velocity = horizontal_velocity
		is_momentum_preserved = true
	
	offset_velocity = direction / 2
	
	horizontal_velocity = horizontal_velocity + offset_velocity
	
	if original_horizontal_velocity.length() <= WALK_SPEED:
		horizontal_velocity = clamp_vector(horizontal_velocity, WALK_SPEED)
	else:
		horizontal_velocity = clamp_vector(horizontal_velocity, original_horizontal_velocity.length())
	
	# Movement vector calculated from horizontal direction and gravity.
	movement.z = horizontal_velocity.z + gravity_vector.z
	movement.x = horizontal_velocity.x + gravity_vector.x
	movement.y = gravity_vector.y
	
	# Final velocity calculated from movement.
	set_velocity(movement)
	
	move_and_slide()


			




func jump():
	gravity_vector = Vector3.UP * JUMP_VELOCITY

# Used instead of clamp() so that the vector in question is limited
# to a circle instead of a square.
func clamp_vector(vector: Vector3, clamp_length: float) -> Vector3:
	if vector.length() <= clamp_length:
		return vector
	return vector * (clamp_length / vector.length())

func _on_projectile_fired(item_data, projectile_transform):
	print("shoot")
	ui.update_ammo(item_data)
	
	#methond 2 recoil
	
	item_manager.fire_recoil()
	
	#method 1 recoil
	# TODO: add recoil and camera shake and stuff!
	#camera_effect_offset += Vector3(0, randf_range(0, .3), randf_range(-.3, .3))
	#var tween = create_tween().set_parallel(true)
	#tween.tween_property(self, "camera_effect_offset", Vector3.ZERO, 0.2).from_current()
	#camera_position_offset += Vector3(0,0.01,0)
	#camera.translate(Vector3(0,0.1,0.01))
	#item_manager.translate(Vector3(0,0.01,0))
	
	#methond 3 recoil
	#camera_recoil_x += 0.05
	#camera_recoil_y += 0
	#wait(0.05)
	#camera_recoil_x += 0.0
	#camera_recoil_y += 0.0
	
	




func _on_player_reloaded(item_data):
	ui.update_ammo(item_data)

func _on_update_player_ui(item_data):
	ui.update_ammo(item_data)
