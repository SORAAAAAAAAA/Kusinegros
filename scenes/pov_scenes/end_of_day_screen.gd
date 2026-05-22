extends Control

# Because we used %, Godot finds these instantly no matter where they are in the folders!
@onready var stats_text = %StatsText
@onready var leave_button = %Leave
@onready var continue_button = %Continue

func _ready():
	# Always hide ourselves when the scene first loads
	hide()
	
	# Connect the buttons
	leave_button.pressed.connect(_on_leave_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

# We call this exactly when all customers leave!
func show_summary():
	# 1. Grab the exact numbers from the brain
	var served = GameManager.customers_served_today
	var profit = GameManager.daily_earnings
	
	# 2. Update the text on the screen
	stats_text.text = "Customer: " + str(served) + "\nProfit: " + str(profit)
	
	# 3. Reveal the screen
	show()
	
func _on_continue_pressed():
	# 1. Advance the global day counter!
	GameManager.current_day += 1
	GameManager.day_changed.emit(GameManager.current_day)
	
	# THE FIX: Stop the clock and wind it back to zero. 
	# DO NOT call GameManager.start_new_shift() here!
	GameManager.is_shop_open = false
	GameManager.time_elapsed = 0.0
	
	# 3. Reload the room
	get_tree().change_scene_to_file("res://scenes/pov_scenes/main_pov.tscn")

func _on_leave_pressed():
	print("Shift abandoned! Returning to Main Menu...")
	# Change this path to match your actual Main Menu scene!
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
