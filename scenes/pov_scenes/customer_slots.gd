extends HBoxContainer

# NEW: This allows you to drag multiple different customer .tscn files into a list!
@export var customer_scenes: Array[PackedScene] = []

func _ready():
	pass

func _on_spawn_timer_timeout():
	# 1. Safety check: make sure you actually put scenes in the inspector list
	if customer_scenes.size() == 0:
		print("WARNING: No customer scenes assigned to the CustomerSlots array!")
		return

	# 2. Count how many actual customers are standing at the counter right now
	var current_customers = 0
	for child in get_children():
		if child.name != "SpawnTimer": 
			current_customers += 1
			
	# 3. PROGRESSION SCALABILITY: Max customer capacity limits
	var current_max_customers = clampi(GameManager.current_day + 1, 1, 5)
			
	# 4. Spawn a random customer if there's an open slot at the counter
	if current_customers < current_max_customers:
		
		# NEW: Pick a completely random customer scene from your list!
		var random_customer_scene = customer_scenes.pick_random()
		
		var new_customer = random_customer_scene.instantiate()
		add_child(new_customer)
		print("A new face arrived! Counter: ", current_customers + 1, "/", current_max_customers)
		
		# SPEED SCALABILITY: Make the rush hour faster on later days!
		var new_speed = maxf(5.0 - (GameManager.current_day * 0.5), 2.5)
		$SpawnTimer.wait_time = new_speed
	else:
		print("Counter full for Day ", GameManager.current_day, ". Max limit: ", current_max_customers)
