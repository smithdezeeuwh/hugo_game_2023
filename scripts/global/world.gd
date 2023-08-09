extends Node3D

@onready var player = $Player
@onready var enemy = load("res://scenes/enemy.tscn")
var enemy_spawns: int = 0
var max_timer = 10
var timer = max_timer

# Called when the node enters the scene tree for the first time.

func wait(t):
	await get_tree().create_timer(t).timeout

func _ready():
	pass

func _physics_process(delta):
	if enemy_spawns > 0:
		if timer < 0:
			spawn_enemy()
			spawn_enemy()
			spawn_enemy()
			enemy_spawns -= 3
			timer = max_timer
		timer -= 1

func spawn_enemy():
	var new_enemy = enemy.instantiate()
	new_enemy.position = Vector3(randf_range(-100, 100), 20.0, randf_range(-100, 100))
	add_child(new_enemy)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
