extends Area3D



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	print("weihfosidhfiuhwe")
	if body.is_in_group("Player"):
		body.ammo_box_pickup()


func _on_area_entered(area):
	print("fr")
