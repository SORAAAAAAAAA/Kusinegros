extends Control 


# 1. Grab our Unique UI Nodes!
@onready var day_number = %DayNumber
@onready var money_text = %MoneyText
@onready var time_text = %TimeText # <-- Added the unique Time node!

# Scene Nodes
@onready var scene_transition = $HUD/SceneTransition
@onready var sfx_start = $SfxStart
@onready var sfx_clicked = $SfxClicked
@onready var switch_pov_button = %SwitchPOVButton

# Core Loop Nodes (Make sure to right-click these and "Access as Unique Name" too!)
@onready var customer_container = %CustomerSlots
@onready var end_of_day_screen = %EndOfDayScreen

func _ready():
	sfx_start.play()
	switch_pov_button.pressed.connect(_on_switch_pov_button_pressed)
	
	# Hide the end of day screen at the start of the shift
	if end_of_day_screen:
		end_of_day_screen.hide()

	# 2. CONNECT THE RADIO SIGNALS
	# Listen to the GameManager for all HUD updates
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.day_changed.connect(_on_day_changed)
	
	# Listen to the GameManager for the Clock and Shift status
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.shift_ended.connect(_on_shift_ended)
	
	# 3. INITIALIZE THE UI
	# Assuming GameManager has these variables, force an update on load
	if "money" in GameManager:
		_on_money_changed(GameManager.money)
	_on_day_changed(GameManager.current_day)
	
	# --- THE FADE IN TRANSITION ---
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(scene_transition, "modulate:a", 0.0, 0.8)
	tween.tween_callback(scene_transition.hide)

	if not GameManager.is_shop_open and GameManager.time_elapsed == 0.0:
		GameManager.start_new_shift()
		
	# 5. REBUILD THE ROOM
	_rebuild_room()


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


# 6. THE END-OF-DAY CHECK
func _process(delta):
	# We constantly check: Is the shop closed? Is the end screen NOT visible yet?
	if not GameManager.is_shop_open and end_of_day_screen and not end_of_day_screen.visible:
		
		# If the shop is closed, wait patiently for the remaining customers to leave.
		# Once the container hits 0, trigger the Day Summary!
		if customer_container.get_child_count() == 0:
			_show_day_summary()

func _show_day_summary():
	print("All customers cleared. Showing summary.")
	end_of_day_screen.show()


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
	
func _rebuild_room():
	print("--- ROOM REBUILD TRIGGERED ---")
	print("Brain Memory: ", GameManager.active_customers.size(), " customers waiting.")
	
	for id in GameManager.active_customers.keys():
		var data = GameManager.active_customers[id]
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
