extends CanvasLayer

@onready var quit_button = %QuitButton
@onready var back_button = %BackButton
@onready var volume_slider: HSlider = %VolumeSlider
var master_bus_index: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	
	master_bus_index = AudioServer.get_bus_index("Master")
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus_index))
	
func open_settings():
	show()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_volume_slider_value_changed(value: float) -> void:
	
	# Convert the slider's 0.0-1.0 number into Decibels, and apply it to the game!
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))
	
	print("Settings: Master volume changed to ", value)
	
func _on_back_button_pressed() -> void:
	hide()
	
func _on_quit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	hide()	
