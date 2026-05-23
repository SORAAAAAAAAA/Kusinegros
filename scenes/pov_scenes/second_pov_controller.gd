extends Control

# --- DUAL ASSET EXPORTS ---
@export var table_scene: PackedScene          
@export var table_flipped_scene: PackedScene  
@export var diner_customer_scene: PackedScene # <--- Your Puppet Scene!

@onready var tables_container: Control = $TablesContainer
@onready var table_manager: TableManager = $TableManager
@onready var counter_button: TextureButton = $Counter 
@onready var spawn_door: Marker2D = $SpawnDoor        

# --- QUEUE SYSTEM ---
@onready var wait_line_container = $WaitLine 

# THE FIX 1: Untyped array prevents Godot 4 from wiping your queue memory!
var waiting_queue: Array = [] 

var all_table_positions: Array[Vector2] = [
	Vector2(203.0, 131.0),
	Vector2(-115.0, 6.0),
	Vector2(191.0, 6.0),
	Vector2(-157.0, 131.0)
]

func _ready() -> void:
	spawn_all_tables()
	
	if counter_button:
		counter_button.pressed.connect(_on_counter_pressed)
		
	if has_node("/root/CustomerManager"):
		CustomerManager.day_completely_cleared.connect(_force_return_to_main)
		
	if has_node("/root/GameManager"):
		GameManager.customer_ready_to_eat.connect(_on_incoming_customer)

func spawn_all_tables() -> void:
	var extra_tables_count: int = 3
	if has_node("/root/GameManager"):
		var global_manager = get_node("/root/GameManager")
		if "unlocked_tables_count" in global_manager:
			extra_tables_count = global_manager.unlocked_tables_count

	var total_tables_to_spawn = 1 + extra_tables_count 
	for i in range(total_tables_to_spawn):
		if i < all_table_positions.size():
			spawn_table_from_shop(all_table_positions[i], i)

func spawn_table_from_shop(spawn_coord: Vector2, index: int) -> void:
	var table_number = index + 1 
	var new_table: TableControl
	
	if table_number == 2 or table_number == 4:
		new_table = table_flipped_scene.instantiate() as TableControl
	else:
		new_table = table_scene.instantiate() as TableControl
		
	new_table.name = "Table_" + str(table_number) 
	new_table.position = spawn_coord
	tables_container.add_child(new_table)
	
	# --- REQUIRED: CONNECT CLEANING SIGNAL ---
	new_table.table_cleaned.connect(_on_any_table_cleaned)
	table_manager.register_table(new_table)

# =====================================================================
# CUSTOMER SEATING & QUEUE GATEWAY
# =====================================================================
func request_seat_for_customer() -> Marker2D:
	if table_manager:
		return table_manager.find_available_seat()
	return null

func _on_incoming_customer(customer_data: Dictionary) -> void:
	var target_stool_marker = request_seat_for_customer()
	
	if target_stool_marker != null:
		# TABLE IS OPEN: Spawn the puppet directly!
		if not diner_customer_scene: return
		var puppet = diner_customer_scene.instantiate()
		target_stool_marker.add_child(puppet)
		
		if spawn_door: puppet.global_position = spawn_door.global_position 
		puppet.setup_and_seat(customer_data)
	else:
		# --- THE FIX: GET OR BUILD THE SCENE PATH ---
		if not customer_data.has("scene_path") or customer_data["scene_path"] == "":
			
			# ATTEMPT 1: Ask the Brain (Works if they haven't ordered yet)
			if customer_data.has("id") and CustomerManager.active_customers.has(customer_data["id"]):
				customer_data["scene_path"] = CustomerManager.active_customers[customer_data["id"]]["scene_path"]
				
			# ATTEMPT 2: Build it from their name (Works if they just paid and were deleted from the Brain)
			elif customer_data.has("name") and customer_data["name"] != "":
				var clean_name = customer_data["name"].to_lower()
				customer_data["scene_path"] = "res://scenes/customer_scenes/" + clean_name + ".tscn"
				
		# Final Safety Check
		if not customer_data.has("scene_path") or customer_data["scene_path"] == "": 
			print("2nd POV Error: Missing scene path for queue! Data: ", customer_data)
			return
		
		# TABLE FULL: Spawn the original scene in the queue!
		var original_scene = load(customer_data["scene_path"])
		if not original_scene: return
		
		var queue_customer = original_scene.instantiate()
		var wait_spots = wait_line_container.get_children()
		
		# Safely clean the queue without wiping the array data
		for i in range(waiting_queue.size() - 1, -1, -1):
			if not is_instance_valid(waiting_queue[i]):
				waiting_queue.remove_at(i)
		
		if waiting_queue.size() < wait_spots.size():
			var assigned_spot = wait_spots[waiting_queue.size()]
			assigned_spot.add_child(queue_customer)
			
			if spawn_door: queue_customer.global_position = spawn_door.global_position 
			queue_customer.setup_and_wait(customer_data)
			waiting_queue.append(queue_customer)
		else:
			print("2nd POV: Wait line is full! Customer walked away.")

func _on_any_table_cleaned(table: Node) -> void:
	# Wait 0.1 seconds so the TableManager can mark the seat empty!
	await get_tree().create_timer(0.1).timeout
	
	# Safely clean the queue again
	for i in range(waiting_queue.size() - 1, -1, -1):
		if not is_instance_valid(waiting_queue[i]):
			waiting_queue.remove_at(i)
	
	# A flag to track if we actually moved anyone, so we only shuffle the line once
	var line_was_advanced = false
	
	# --- THE KEEP SEATING LOOP ---
	# As long as there are people in line, keep asking for seats!
	while waiting_queue.size() > 0:
		var new_stool = request_seat_for_customer()
		
		# If we found an empty stool, seat the next person
		if new_stool != null:
			var next_in_line = waiting_queue.pop_front()
			var saved_data = next_in_line.my_data
			var current_global_pos = next_in_line.global_position
			
			next_in_line.queue_free()
			
			var puppet = diner_customer_scene.instantiate()
			new_stool.add_child(puppet)
			puppet.global_position = current_global_pos 
			puppet.setup_and_seat(saved_data)
			
			line_was_advanced = true
		else:
			# No more seats available! Break out of the loop completely.
			break
			
	# --- SHUFFLE THE LINE ---
	# Only do this ONCE after everyone possible has been seated
	if line_was_advanced:
		var wait_spots = wait_line_container.get_children()
		for i in range(waiting_queue.size()):
			waiting_queue[i].advance_in_line(wait_spots[i])

# =====================================================================
# SCENE TRANSITIONS
# =====================================================================
func _on_counter_pressed() -> void:
	var game_master = get_parent()
	if game_master and game_master.has_method("go_to_main_pov"):
		game_master.go_to_main_pov()
		
func _force_return_to_main():
	var game_master = get_parent()
	if game_master and game_master.has_method("go_to_main_pov"):
		game_master.go_to_main_pov()
