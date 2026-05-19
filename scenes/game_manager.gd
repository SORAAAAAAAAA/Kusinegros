extends Node

# --- GAME STATS ---
var money: int = 0
var active_orders: Array = []

var available_menu: Array = ["adobo", "pastil", "menudo", "pansit", "sisig", "carbonara"] 

# --- SIGNALS (To update your UI) ---
signal money_changed(new_amount)
signal order_added(dish_name)
signal order_completed(dish_name)

# Call this on a timer, or when a customer walks in
func generate_new_order():
	# Pick a random food from the menu
	var random_dish = available_menu.pick_random()
	active_orders.append(random_dish)
	
	print("New order received: ", random_dish)
	order_added.emit(random_dish) # Tells the UI to draw a speech bubble

# Call this when the player drops a plate on a customer
func try_serve_plate(plate_ulam: String) -> bool:
	# Check if any customer actually ordered this food
	if plate_ulam in active_orders:
		
		# Success! Remove the order and give the player money
		active_orders.erase(plate_ulam)
		money += 50 # Add 50 pesos/coins
		print("Successfully served: ", plate_ulam, " | Total Money: ", money)
		
		money_changed.emit(money) # Tells the UI to update the money text
		order_completed.emit(plate_ulam) # Tells the UI to remove the speech bubble
		
		return true # Tell the plate it was a successful drop
	else:
		print("Nobody ordered ", plate_ulam, "!")
		return false # Tell the plate it was rejected
