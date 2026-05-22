extends Node

var customers_served_today: int = 0

func start_new_shift():
	# The General Manager resets his own notebook...
	customers_served_today = 0
	# ...and tells the rest of the staff to get to work!
	TimeManager.start_new_day()
	FinanceManager.reset_daily_earnings()
	CustomerManager.reset_for_new_shift()
	KitchenManager.reset_kitchen()


func process_successful_sale(dish_name: String, payment_amount: int, customer_id: int):
	customers_served_today += 1
	# Hand the money to the Bank
	FinanceManager.add_funds(payment_amount, dish_name)
	
	# Tell the Hostess they left!
	CustomerManager.remove_customer(customer_id)
