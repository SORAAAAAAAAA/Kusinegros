extends Control 

# 1. Grab our Unique UI Nodes!
@onready var day_number = %DayNumber
@onready var money_text = %MoneyText
@onready var time_text = %TimeText # <-- Added the unique Time node!

# Scene Nodes
@onready var scene_transition = $HUD/SceneTransition
@onready var sfx_start = $SfxStart

# Core Loop Nodes (Make sure to right-click these and "Access as Unique Name" too!)
@onready var customer_container = %CustomerContainer
@onready var end_of_day_screen = %EndOfDayScreen

func _ready():
	sfx_start.play()
	
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

	# 4. START THE CLOCK!
	# Tell the global brain to begin the shift
	GameManager.start_new_shift()


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
