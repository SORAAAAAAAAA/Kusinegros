extends Control 

# 1. Grab our Unique UI Nodes!
@onready var day_number = %DayNumber
@onready var money_text = %MoneyText
@onready var time_text = %TimeText 
@export var plate_scene: PackedScene

# Scene Nodes
@onready var scene_transition = $HUD/SceneTransition
@onready var sfx_start = $SfxStart
@onready var sfx_clicked = $SfxClicked
@onready var switch_pov_button = %SwitchPOVButton

# Core Loop Nodes (Make sure to right-click these and "Access as Unique Name" too!)
@onready var customer_container = %CustomerSlots
@onready var end_of_day_screen = %EndOfDayScreen
@onready var plate_container = $GridContainerPlates


func _ready():
	switch_pov_button.pressed.connect(_on_switch_pov_button_pressed)
	
	if end_of_day_screen:
		end_of_day_screen.hide()

	# 1. CONNECT THE RADIO SIGNALS
	FinanceManager.money_changed.connect(_on_money_changed)
	TimeManager.day_changed.connect(_on_day_changed)
	TimeManager.time_updated.connect(_on_time_updated)
	TimeManager.shift_ended.connect(_on_shift_ended)
	
	# Listen for live spawns
	CustomerManager.live_customer_spawned.connect(_on_live_spawn_received)
	
	# 2. INITIALIZE THE UI
	if "total_money" in FinanceManager:
		_on_money_changed(FinanceManager.total_money)
		
	_on_day_changed(TimeManager.current_day)


	# --- 3. THE MVC STARTUP CHECK ---
	# Check the Global Brain: Is it exactly 7:00 AM?
	if TimeManager.time_elapsed == 0.0:
		# Yes! This is the very first time we are loading the day.
		if sfx_start:
			sfx_start.play()
			
		if scene_transition:
			scene_transition.show()
			var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(scene_transition, "modulate:a", 0.0, 0.8)
			tween.tween_callback(scene_transition.hide)

		# Start the clock!
		GameManager.start_new_shift()
		
	else:
		# No! Time has already passed. We are just returning from the 2nd POV.
		# Skip the sound, skip the timer restart, and instantly hide the black screen!
		if scene_transition:
			scene_transition.hide()

	# 4. REBUILD THE ROOM
	_rebuild_room()
	_rebuild_plates()
	
	if CustomerManager.is_day_completely_over:
		_trigger_end_of_day()


# 5. THE UPDATE FUNCTIONS
# These run automatically whenever the GameManager shouts that a change happened!

func _on_money_changed(new_amount: int):
	# Update the money
	money_text.text = " " + str(new_amount)

func _on_day_changed(new_day: int):
	# Update the day number
	day_number.text = str(new_day)

func _on_time_updated(time_string: String):
	# Update the bamboo clock!
	time_text.text = time_string

func _on_shift_ended():
	# The clock hit 5:00 PM! 
	print("5:00 PM! The doors are closed!")
	# Note: If you have a Customer Spawner script/timer, tell it to stop spawning here!


# =====================================================================
# INSTANT SCENE TRANSITION
# =====================================================================
func _on_switch_pov_button_pressed() -> void:
	if sfx_clicked: 
		sfx_clicked.play()
	
	print("Switch POV clicked! Moving to 2nd POV...")
	
	# Because the GameManager tracks IDs in real-time now, 
	# we just instantly leave! The brain will remember everything.
	get_tree().change_scene_to_file("res://scenes/pov_scenes/2nd_pov.tscn")

func _rebuild_plates():
	print("--- REBUILDING DYNAMIC PLATES ---")
	
	# Sweep the room of accidental editor plates
	for child in plate_container.get_children():
		child.queue_free()
		
	# THE FIX: Loop through the Dictionary Keys!
	for id in KitchenManager.plate_memory.keys():
		
		var restored_plate = plate_scene.instantiate()
		
		# Inject the exact ID from the dictionary!
		restored_plate.my_plate_index = id
		
		plate_container.add_child(restored_plate)
		
		var saved_food = KitchenManager.plate_memory[id]
		if saved_food != "":
			restored_plate.add_food_to_plate(saved_food)
			print("Restored ", saved_food, " on Plate ID ", id)
	
func _rebuild_room():
	print("--- ROOM REBUILD TRIGGERED ---")
	print("Brain Memory: ", CustomerManager.active_customers.size(), " customers waiting.")
	
	for id in CustomerManager.active_customers.keys():
		var data = CustomerManager.active_customers[id]
		var path = data["scene_path"]
		
		# Safety Check 1: Did we get a valid file path?
		if path == null or path == "":
			print("ERROR: Customer ID ", id, " has an empty scene_path! Cannot rebuild.")
			continue 
			
		var specific_character_scene = load(path)
		
		# Safety Check 2: Did the file load correctly?
		if specific_character_scene:
			var restored_customer = specific_character_scene.instantiate()
			
			# Inject the memory!
			restored_customer.my_global_id = id
			restored_customer.my_current_order = data["order"]
			
			# Put them back at the counter
			customer_container.add_child(restored_customer)
			print("Successfully rebuilt Customer ID: ", id, " with order: ", data["order"])
		else:
			print("ERROR: Could not load the scene file at: ", path)
			
func _on_live_spawn_received(id: int):
	# Grab their data from the brain
	var data = CustomerManager.active_customers[id]
	var specific_character_scene = load(data["scene_path"])
	
	if specific_character_scene:
		var puppet = specific_character_scene.instantiate()

		puppet.my_global_id = id
		puppet.my_current_order = data["order"]
		
		# TELL THE PUPPET TO PLAY ITS INTRO ANIMATION
		puppet.play_spawn_animation = true 
		
		customer_container.add_child(puppet)
		
func _trigger_end_of_day():
	print("All customers cleared. Showing summary.")
	%EndOfDayScreen.show_summary()
