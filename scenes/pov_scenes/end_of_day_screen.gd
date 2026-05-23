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
	# Grab the profit from the Bank, and the customer count from the Hostess (GameManager)
	var profit = FinanceManager.daily_earnings
	var served = GameManager.customers_served_today
	
	stats_text.text = "Customer: " + str(served) + "\nProfit: " + str(profit)
	show()
	
func _on_continue_pressed():
	SaveManager.save_game()
	# Reload the room
	get_tree().change_scene_to_file("res://scenes/pov_scenes/main_pov.tscn")

func _on_leave_pressed():
	SaveManager.save_game()
	print("Shift abandoned! Returning to Main Menu...")
	
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
