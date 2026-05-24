extends Node

var customers_served_today: int = 0

# --- NEW: Table Shop Tracking ---
var unlocked_tables_count: int = 0
signal new_table_purchased(new_extra_count: int)
# --------------------------------

signal customer_ready_to_eat(customer_data: Dictionary)

func start_new_shift():
	# The General Manager resets his own notebook...
	customers_served_today = 0
	# ...and tells the rest of the staff to get to work!
	TimeManager.start_new_day()
	FinanceManager.reset_daily_earnings()
	CustomerManager.reset_for_new_shift()
	KitchenManager.reset_kitchen()


# THE UPDATE: Added 'customer_name: String' as the 4th requirement
func process_successful_sale(dish_name: String, payment_amount: int, customer_id: int, customer_name: String):
	customers_served_today += 1
	# Hand the money to the Bank
	FinanceManager.add_funds(payment_amount, dish_name)
	
	# Tell the Hostess they left!
	CustomerManager.remove_customer(customer_id)
	
	# --- NEW: Package data for the 2nd POV puppet ---
	var customer_data = {
		"id": customer_id,
		"order": dish_name,
		"payment": payment_amount,
		"name": customer_name
	}
	
	# Shout to the 2nd POV that a customer is ready to walk in!
	customer_ready_to_eat.emit(customer_data)
