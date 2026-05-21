extends Control 

# 1. Grab our Unique UI Nodes!
@onready var day_number = %DayNumber
@onready var money_text = %MoneyText

func _ready():
	# 2. CONNECT THE RADIO SIGNALS
	# Tell the UI to listen to the GameManager, and run our update functions when it hears something.
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.day_changed.connect(_on_day_changed)
	
	# 3. INITIALIZE THE UI
	# When the game first boots up, the text will say whatever you typed in the editor.
	# We force an update right now so it correctly displays Day 1 and ₱0.
	_on_money_changed(GameManager.money)
	_on_day_changed(GameManager.current_day)


# 4. THE UPDATE FUNCTIONS
# These run automatically whenever the GameManager shouts that a change happened!

func _on_money_changed(new_amount: int):
	# Update the money
	money_text.text = " " + str(new_amount)

func _on_day_changed(new_day: int):
	# Update the day number
	day_number.text = str(new_day)
