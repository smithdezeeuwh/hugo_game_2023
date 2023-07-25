extends CanvasLayer


@onready var main: Control = $Main
@onready var settings: Control = $Settings
@onready var difficulty = $Settings/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Difficulty

var difficulty_from_load:int = 0 

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_button_play_pressed():
	get_tree().change_scene_to_file("res://scenes/world.tscn")


func _on_button_setting_pressed():
	main.visible = false
	settings.visible = true


func _on_button_quit_pressed():
	get_tree().quit()


func _on_settings_back_pressed():
	main.visible = true
	settings.visible = false
	

# this is called if difficulty slider is moved value is the difficulty
func _on_h_slider_value_changed(value):
	# changes the difficulty label based on difficulty
	if value ==1:
		difficulty.text = str("Easy")
	if value ==2:
		difficulty.text = str("Medium")
	if value ==3:
		difficulty.text = str("Hard")
	#gets save location
	var savelocation = OS.get_executable_path()
	#finds save file
	var file = FileAccess.open("user://save.txt", FileAccess.WRITE)
	#saves difficulty for use in game scene
	file.store_string(str(value))
	

func load_difficulty():
	var file = FileAccess.open("user://save.txt", FileAccess.READ)
	difficulty_from_load = int(file.get_as_text(true))


