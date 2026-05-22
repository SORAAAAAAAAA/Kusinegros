extends Node

# --- SIGNALS ---
signal money_changed(new_amount: int)

# --- VARIABLES ---
var total_money: int = 0
var daily_earnings: int = 0

# --- FUNCTIONS ---
func add_funds(amount: int, reason: String = ""):
	total_money += amount
	daily_earnings += amount
	print("Bank: Earned ", amount, " for ", reason, " | Total Balance: ", total_money)
	money_changed.emit(total_money)

func deduct_funds(amount: int):
	# (For the future, if you want to buy upgrades or penalize the player!)
	total_money -= amount
	money_changed.emit(total_money)

func reset_daily_earnings():
	daily_earnings = 0
