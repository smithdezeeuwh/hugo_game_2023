extends Node3D

#@export var defult_position : vector3
@export var defult_position : Vector3
@export var ads_position : Vector3
@export var recoil_position : Vector3
@export var recoil_rotation: Vector3
const ads_lerp = 20
var is_ADS: bool
const recoil_lerp = 0.2


var current_item_slot = "Secondary"
var item_index: int = 1 # For switching items via scroll wheel, which requires a numeric key.
var is_changing_item: bool = true

@onready var all_items: Dictionary = {
	"ak_47":preload("res://scenes/items/ak_47.tscn")
}

# IMPORTANT: Make sure these are in the same order as update_item_index().
@onready var items: Dictionary = {
	"Melee":$Fists,
	"Primary":$pkm,
	"Secondary":$ak_74u,
	"Grenade":null
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	request_action("equip", current_item_slot)
	
	update_item_index()
	
func _physics_process(delta: float) -> void:
	ADS(delta)

func set_item(item: String, slot: String = current_item_slot) -> void:
	request_action("drop_item", slot)
	items[slot] = call_deferred("add_child", all_items[item]) # Will create new slot entry if incorrect!
	
	print(items)

func get_item():
	pass

func request_action(item_action: String, slot: String = current_item_slot) -> void:
	if items[slot] != null:
		items[slot].request_action(item_action)
	else:
		print("No item currently equipped in slot " + slot)
	
	if item_action == "drop_item" and slot == current_item_slot:
		print(current_item_slot + str(item_index))
		next_item()

func equip_primary():
	print("equip primary request part 2")
	request_action("unequip")
	set_current_item(items.keys()[1])

func equip_secondary():
	request_action("unequip")
	set_current_item(items.keys()[2])

func equip_melee():
	request_action("unequip")
	set_current_item(items.keys()[0])
	
func ADS(delta):
	if Input.is_action_pressed("ADS"):
		#print("ADS")
		transform.origin = transform.origin.lerp(items[current_item_slot].item_data.ads_position, ads_lerp * delta)
		print(items[current_item_slot])
		print(items[current_item_slot].item_data.ads_position)
		#transform.origin = transform.origin.lerp(ads_position, ads_lerp * delta)
		is_ADS = true
	else: 
		transform.origin = transform.origin.lerp(defult_position, ads_lerp * delta)
		is_ADS = false

func is_ads():
	return is_ADS

func fire_recoil():
	pass
	#transform.origin = transform.origin.lerp(recoil_position,  recoil_lerp)
		
# There would be an infinite loop for these two if we had no items at all,
# which is why we must always have a 'fists' item in the melee slot at the least.
func next_item():
	item_index += 1
	
	if item_index >= items.size():
		item_index = 0
	
	if items[items.keys()[item_index]] == null:
		print("null")
		next_item()
	else:
		print("not null")
		request_action("unequip") # Unequip currently-held item.
		set_current_item(items.keys()[item_index])

func previous_item():
	item_index -= 1
	
	if item_index < 0:
		item_index = items.size() - 1
	
	if items[items.keys()[item_index]] == null:
		previous_item()
	else:
		request_action("unequip") # Unequip currently-held item.
		set_current_item(items.keys()[item_index])

func set_current_item(item_slot: String):
	print("current item set")
	current_item_slot = item_slot
	request_action("equip")
	print(current_item_slot + str(item_index))
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
		var body = raycast.get_collider()
		
		if body.is_in_group("pickup"):
			var item_data = body.get_item_pickup_data()
			print(item_data)
			print("ranga")
			
			#show_interaction_prompt(item_data)
			
			if Input.is_action_just_pressed("interact"):
				#replace_item(item_data)
				body.queue_free()
			return
		
	else:
		pass
		#hide_interaction_prompt()


