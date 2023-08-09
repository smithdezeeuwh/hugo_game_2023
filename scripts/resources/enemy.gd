extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@onready var player = get_parent().get_child(2)
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
	move(delta)


func got_hit():
	queue_free()


func move(delta):
	# Add the gravity.
	#if not is_on_floor():
	#	velocity.y -= gravity * delta
	velocity = basis.z * -10.0
	look_at(player.position)

	move_and_slide()

