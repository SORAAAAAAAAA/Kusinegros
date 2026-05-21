extends Node

# --- GAME STATS ---
var money: int = 0
var current_day: int = 1 # The game starts on Day 1

var available_menu: Dictionary = {
	"ulam": ["adobo", "pastil", "menudo", "pansit", "sisig", "carbonara", "cordon"],
	"rice": ["rice"] 
} 

# --- SIGNALS ---
signal money_changed(new_amount)
signal day_changed(new_day)

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
	money += payment_amount
	print("Sale processed for: ", dish_name, " | Earned: ", payment_amount, " | Total Money: ", money)
	money_changed.emit(money)

# Call this when the player finishes a shift!
func advance_to_next_day():
	current_day += 1
	print("Starting Day ", current_day, "!")
	day_changed.emit(current_day)
