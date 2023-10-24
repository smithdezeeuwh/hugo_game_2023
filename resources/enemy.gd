extends CharacterBody3D

var bullet: PackedScene = load("res://scenes/projectiles/bullet.tscn")
@onready var gun_data: ItemData = load("res://data/item_data/ak_47.tres")

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var health = 50
var maxbullettime = 5
var bullettime = maxbullettime
@onready var muzzle =  $Muzzle
@export var bulletscene: PackedScene
@onready var player = get_parent().get_child(2)
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")



func _physics_process(delta):
	bullettime -= 0.1
	velocity = -basis.z * 5
	velocity.y = -10
	look_at(player.position)
	rotation.x = 0
	rotation.z = 0
	move_and_slide()
	if bullettime <0:
		fire()
		bullettime = maxbullettime

func damage(amount):
	health -= amount
	if health <= 0:
		health = 0
		die()

func die():
	queue_free()
	
func fire():
	var newbullet = bulletscene.instantiate()
	newbullet.position = muzzle.position
	add_child(newbullet)
	
	#projectile_transform.origin.look_at_from_position(projectile_transform.origin, player.position)
	#projectile_transform.rotation += Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), 0)
	
