extends CanvasLayer

@onready var health_text = $MarginContainer/Health
@onready var ammo_text = $MarginContainer/Ammo
@onready var speed_text = $MarginContainer/Speed
@onready var pickup_prompt = $MarginContainer/PickupPrompt


@onready var scope_overlay = $MarginContainer/ZoomOverlay
var is_scoping:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scope_overlay.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func update_ammo(item_data: ItemData) -> void:
	if item_data.slot_type == "Melee":
		ammo_text.hide()
		return
	
	ammo_text.show()
	
	ammo_text.text = str(item_data.current_clip_ammo) + "/" + str(item_data.current_extra_ammo)
	
func update_speed(speed):
	speed_text.text = str(speed)
	
func update_player_health(health):
	health_text.text = "Health:" + str(health) + "/100"
	
func scope():
	scope_overlay.show()

func not_scope():
	#print
	scope_overlay.hide()


