extends CanvasLayer

@onready var health_text = $HealthRect/HealthText
@onready var ammo_text = $AmmoRect/AmmoText
@onready var speed_text = $SpeedRect/SpeedText


@onready var health_rect = $HealthRect
@onready var ammo_rect = $AmmoRect
@onready var speed_rect = $SpeedRect
@onready var scope_overlay = $Zoom_overlay
var is_scoping:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scope_overlay.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func update_ammo(item_data: ItemData) -> void:
	if item_data.slot_type == "Melee":
		ammo_rect.hide()
		return
	
	ammo_rect.show()
	
	ammo_text.text = str(item_data.current_clip_ammo) + "/" + str(item_data.current_extra_ammo)
	
func update_speed(speed):
	speed_text.text = str(speed)
	
func scope():
	scope_overlay.show()

func not_scope():
	#print
	scope_overlay.hide()


