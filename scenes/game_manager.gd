extends Node

# --- SIGNALS (The Broadcasters) ---
signal shift_ended
signal time_updated(time_string: String)

# --- Progression Variables ---
var current_day: int = 1
var total_money: int = 0
var daily_earnings: int = 0

# --- CLOCK VARIABLES ---
var shift_duration: float = 90.0 # How long a day is in real seconds
var time_elapsed: float = 0.0
var is_shop_open: bool = false

var available_menu: Dictionary = {
	"ulam": ["adobo", "pastil", "menudo", "pansit", "carbonara", "cordon", "finger", "hamonado", "bbq","mushroom"],
	"rice": ["rice"] 
} 

# --- SIGNALS ---
signal money_changed(new_amount)
signal day_changed(new_day)

func _process(delta: float) -> void:
	# If the shop is closed, stop running the clock
	if not is_shop_open:
		return
		
	time_elapsed += delta
	
	if time_elapsed >= shift_duration:
		# OUT OF TIME!
		is_shop_open = false
		shift_ended.emit() 
		_broadcast_time(1.0) # Force the clock to exactly 5:00 PM
	else:
		# Tell the game exactly what percentage of the day is done
		var percent = time_elapsed / shift_duration
		_broadcast_time(percent)


func start_new_shift():
	# Reset the clock for the new day
	time_elapsed = 0.0
	is_shop_open = true
	_broadcast_time(0.0) 
	print("--- DAY ", current_day, " STARTED! ---")


func _broadcast_time(percent_passed: float):
	# 1. Math to calculate the 10-hour shift (7 AM - 5 PM)
	var total_shift_minutes = 600.0 
	var in_game_minutes = percent_passed * total_shift_minutes
	var current_time_in_minutes = 420 + in_game_minutes
	
	var hour = int(current_time_in_minutes / 60)
	var minute = int(current_time_in_minutes) % 60
	
	var am_pm = "AM"
	if hour >= 12:
		am_pm = "PM"
		
	var display_hour = hour
	if display_hour > 12:
		display_hour -= 12
	elif display_hour == 0:
		display_hour = 12
		
	# 2. Format it cleanly
	var time_string = str(display_hour) + ":" + ("%02d" % minute) + " " + am_pm
	
	# 3. YELL IT TO THE WORLD! Any script listening to this signal will get this string.
	time_updated.emit(time_string)

# Call this when a customer spawns
func get_random_order() -> String:
	var chance = randi_range(1, 100)
	
	if chance <= 33:
		# 33% Chance: Just Ulam
		return available_menu["ulam"].pick_random()
	elif chance <= 66:
		# 33% Chance: Just Rice
		return "rice"
	else:
		# 34% Chance: COMBO MEAL!
		# Pick a random ulam, and add "_rice" to it (e.g., "adobo_rice")
		var chosen_ulam = available_menu["ulam"].pick_random()
		return chosen_ulam + "_rice"

# Call this when a specific customer confirms they got the right food
func process_successful_sale(dish_name: String, payment_amount: int):
	daily_earnings += payment_amount
	print("Sale processed for: ", dish_name, " | Earned: ", payment_amount, " | Total Money: ", total_money)
	money_changed.emit(daily_earnings)

# Call this when the player clicks "Next Day"
func start_next_day():
	total_money += daily_earnings
	daily_earnings = 0 # Reset the register for the new day
	current_day += 1
	
	# Reload the main game scene to start the new day!
	get_tree().reload_current_scene()
