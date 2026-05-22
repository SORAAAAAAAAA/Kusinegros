extends Node

var available_customer_scenes: Array[String] = [
	"res://scenes/customer_scenes/ana.tscn", 
	"res://scenes/customer_scenes/juan.tscn",
	"res://scenes/customer_scenes/clara.tscn",
	"res://scenes/customer_scenes/inengga.tscn",
	"res://scenes/customer_scenes/iniga.tscn",
	"res://scenes/customer_scenes/lullu.tscn",
]
var available_menu: Dictionary = {
	"ulam": ["adobo", "pastil", "menudo", "pansit", "carbonara", "cordon", "finger", "hamonado", "bbq","mushroom"],
	"rice": ["rice"] 
} 
var current_spawn_timer: float = 0.0

# The brain will shout this signal when a customer spawns while you are watching!
signal live_customer_spawned(id: int)
signal day_completely_cleared

# --- CUSTOMER DATA TRACKING ---
var active_customers: Dictionary = {}
var next_customer_id: int = 0

# -- Signals
signal customer_angry_leave(id: int)
signal money_changed(new_amount)
signal day_changed(new_day)
signal shift_ended
signal time_updated(time_string: String)

# --- Progression Variables ---
var current_day: int = 1
var total_money: int = 0
var daily_earnings: int = 0
var customers_served_today: int = 0
var is_day_completely_over: bool = false

# --- CLOCK VARIABLES ---
var shift_duration: float = 90.0 # How long a day is in real seconds
var time_elapsed: float = 0.0
var is_shop_open: bool = false

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
		
	# THE REAL-TIME PATIENCE DRAIN
	if is_shop_open:
		var customers_to_remove = []
		
		for id in active_customers.keys():
			active_customers[id]["patience"] -= delta
			
			# Did they run out of time?
			if active_customers[id]["patience"] <= 0:
				customers_to_remove.append(id)
				
		# Process the angry customers!
		for id in customers_to_remove:
			print("Customer ", id, " stormed out! Applying penalty.")
			# (Optional: Subtract money or add a strike here!)	
			
			# Yell at the 2D node to play its walk-out animation
			customer_angry_leave.emit(id) 
			
			# Delete them from the brain
			active_customers.erase(id)
			
		# 2. NEW: THE BACKGROUND SPAWNER
		current_spawn_timer -= delta
		if current_spawn_timer <= 0:
			_try_spawn_background_customer()
			
	if not is_shop_open and not is_day_completely_over:
		# If the shop is closed, check if the brain's memory of customers is finally empty
		print("Brain: The shop is closed")
		is_day_completely_over = true
		day_completely_cleared.emit()
	
func register_new_customer(order: String, max_patience: float, scene_path: String) -> int:
	var id = next_customer_id
	next_customer_id += 1
	
	active_customers[id] = {
		"order": order,
		"patience": max_patience,
		"max_patience": max_patience,
		"scene_path": scene_path 
	}
	return id

func remove_customer(id: int):
	active_customers.erase(id)
	
func start_new_shift():
		# Reset the clock for the new day
		active_customers.clear()
		is_day_completely_over = false
		customers_served_today = 0
		daily_earnings = 0
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
	customers_served_today += 1
	total_money += payment_amount
	daily_earnings += payment_amount
	print("Sale processed for: ", dish_name, " | Earned: ", payment_amount, " | Total Money: ", total_money)
	money_changed.emit(total_money)
	
func _try_spawn_background_customer():
	var max_customers = clampi(current_day + 1, 1, 5)
	# Is there an empty space at the counter?
	if active_customers.size() < max_customers:
		if available_customer_scenes.is_empty(): 
			return
		# Pick a random path and random order
		var random_path = available_customer_scenes.pick_random()
		var random_order = get_random_order()
		
		# 1. THE BRAIN CREATES THE CUSTOMER IN SECRET
		var new_id = register_new_customer(random_order, 30.0, random_path)
		
		# 2. Tell the UI to build them (If the player is currently in the room)
		live_customer_spawned.emit(new_id)
		
		print("Brain spawned customer ", new_id, " in the background!")
		
		# Reset the global timer based on the current Day speed!
		var new_speed = maxf(5.0 - (current_day * 0.5), 2.5)
		current_spawn_timer = new_speed
