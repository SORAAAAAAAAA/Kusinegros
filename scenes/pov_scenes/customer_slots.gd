extends HBoxContainer

# NEW: This allows you to drag multiple different customer .tscn files into a list!
@export var customer_scenes: Array[PackedScene] = []

func _ready():
	pass

func _on_spawn_timer_timeout():
	# --- 1. THE MVC SAFETY CHECK ---
	# If the GameManager says the 5:00 PM shift is over, stop spawning instantly!
	if not GameManager.is_shop_open:
		return

	# 2. Safety check: make sure you actually put scenes in the inspector list
	if customer_scenes.size() == 0:
		print("WARNING: No customer scenes assigned to the CustomerSlots array!")
		return

	# 3. Count how many actual customers are standing at the counter right now
	var current_customers = 0
	for child in get_children():
		if child.name != "SpawnTimer": 
			current_customers += 1
			
	# 4. PROGRESSION SCALABILITY: Max customer capacity limits
	var current_max_customers = clampi(GameManager.current_day + 1, 1, 5)
			
	# 5. Spawn a random customer if there's an open slot at the counter
	if current_customers < current_max_customers:
		
		var random_customer_scene = customer_scenes.pick_random()
		var new_customer = random_customer_scene.instantiate()
		
		# THE MAGIC HAPPENS HERE:
		# The exact millisecond you call add_child(), the customer's _ready() 
		# function runs and it automatically registers itself to the GameManager!
		add_child(new_customer)
		
		print("A new face arrived! Counter: ", current_customers + 1, "/", current_max_customers)
		
		# SPEED SCALABILITY: Make the rush hour faster on later days!
		var new_speed = maxf(5.0 - (GameManager.current_day * 0.5), 2.5)
		$SpawnTimer.wait_time = new_speed
	else:
		print("Counter full", GameManager.current_day, ". Max limit: ", current_max_customers)
