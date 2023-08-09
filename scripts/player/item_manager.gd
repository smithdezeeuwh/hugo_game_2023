extends Node3D

#@export var defult_position : vector3
@export var defult_position : Vector3
@export var ads_position : Vector3
const ads_lerp = 20
var is_ADS: bool
const recoil_lerp = 0.2
var body


var current_item_slot = "Secondary"
var item_index: int = 1 # For switching items via scroll wheel, which requires a numeric key.
var is_changing_item: bool = true
var pickup_item_data: ItemData

@onready var all_items: Dictionary = {
	"AK-74U":$ak_74u,
	"PKM":$pkm,
	"vss":$vss
}

@onready var player = get_parent().get_parent()
# IMPORTANT: Make sure these are in the same order as update_item_index().
# this is the player inventory with defult items set
@onready var items: Dictionary = {
	"Melee":$Fists,
	"Primary":$Fists,
	"Secondary":$Fists,
	"Grenade":null
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	request_action("equip", current_item_slot)
	
	update_item_index()
	
func _physics_process(delta: float) -> void:
	ADS(delta)

func set_item(item: String, slot: String = current_item_slot) -> void:
	items[slot].hide()
	if items[slot].item_data.item_name == "Fists":
		pass
	else:
		var new_pickup: RigidBody3D = items[slot].gun_pickup.instantiate()
		new_pickup.global_position = global_position
		new_pickup.apply_impulse(get_parent().basis.z * -2)
		get_parent().get_parent().get_parent().add_child(new_pickup)
		
	items[slot] = all_items[pickup_item_data.item_name]
	items[slot].item_data = pickup_item_data
	set_current_item(slot)
	

func get_item():
	pass

func request_action(item_action: String, slot: String = current_item_slot) -> void:
	if item_action == "reload" and is_ADS:
		return
	
	if items[slot] != null:

		items[slot].request_action(item_action)
	else:
		print("No item currently equipped in slot " + slot)
		
	
	if item_action == "drop_item" and slot == current_item_slot:

		next_item()

func equip_primary():
	if ! is_ADS:
		print("equip primary request part 2")
		request_action("unequip")
		set_current_item(items.keys()[1])

func equip_secondary():
	if ! is_ADS:
		request_action("unequip")
		set_current_item(items.keys()[2])

func equip_melee():
	if ! is_ADS:
		request_action("unequip")
		set_current_item(items.keys()[0])
	
func ADS(delta):
	if Input.is_action_pressed("ADS"):
		transform.origin = transform.origin.lerp(items[current_item_slot].item_data.ads_position, ads_lerp * delta)
		is_ADS = true
		if items[current_item_slot] == $vss:
			items[current_item_slot].hide()
			player.scope()
	else: 
		transform.origin = transform.origin.lerp(defult_position, ads_lerp * delta)
		is_ADS = false
		items[current_item_slot].show()
		player.not_scope()

func is_ads():
	return is_ADS

func is_vss_current():
	if items[current_item_slot] == $vss:
		return true
	else:
		return false

func fire_recoil():
	pass
	#transform.origin = transform.origin.lerp(recoil_position,  recoil_lerp)
		
# There would be an infinite loop for these two if we had no items at all,
# which is why we must always have a 'fists' item in the melee slot at the least.
func next_item():
	if ! is_ADS:
		item_index += 1
		
		if item_index >= items.size():
			item_index = 0
	
		if items[items.keys()[item_index]] == null:
			next_item()
		else:
			request_action("unequip") # Unequip currently-held item.
			set_current_item(items.keys()[item_index])

func previous_item():
	if ! is_ADS:
		item_index -= 1
		
		if item_index < 0:
			item_index = items.size() - 1
		
		if items[items.keys()[item_index]] == null:
			previous_item()
		else:
			request_action("unequip") # Unequip currently-held item.
			set_current_item(items.keys()[item_index])

func set_current_item(item_slot: String):

	current_item_slot = item_slot
	request_action("equip")

	EventBus.update_player_ui.emit(items[current_item_slot].item_data)

# Scroll item change.
func update_item_index():
	match current_item_slot:
		"Melee":
			item_index = 0
		"Primary":
			item_index = 1
		"Secondary":
			item_index = 2
		"Grenade":
			item_index = 3

func pickup_ammo(new_item_data):
	items[current_item_slot].item_data.current_clip_ammo = new_item_data.current_clip_ammo
# Searches for item pickups, and based on player input executes further tasks
# (will be called from player.gd)

func check_item_pickup(raycast: RayCast3D):
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		body = raycast.get_collider()
		
		if body.is_in_group("pickup"):
			pickup_item_data = body.get_item_pickup_data()
			
			player.ui.pickup_prompt.show()
			
		else:
			player.ui.pickup_prompt.hide()

#pass recoil to player srcipt\
func get_x_recoil():
	return items[current_item_slot].item_data.max_recoil_x
func get_y_recoil():
	return items[current_item_slot].item_data.max_recoil_y



var mouse_mov
var sway_threshold = 5
var sway_lerp = 5
@export var sway_left : Vector3
@export var sway_right : Vector3
@export var sway_normal : Vector3


func _input(event):
	if event is InputEventMouseMotion:
		mouse_mov = -event.relative.x
	
func _process(delta):
	if ! is_ADS:
		if mouse_mov != null:
			if mouse_mov > sway_threshold:
				rotation = rotation.lerp(sway_left, sway_lerp * delta)
			elif mouse_mov < -sway_threshold:
				rotation = rotation.lerp(sway_right, sway_lerp * delta)
			else:
				rotation = rotation.lerp(sway_normal, sway_lerp * delta)

