extends Control

# --- DUAL ASSET EXPORTS ---
@export var table_scene: PackedScene          # Your normal Table.tscn
@export var table_flipped_scene: PackedScene  # Your new Table_Flipped.tscn

@onready var tables_container: Control = $TablesContainer
@onready var table_manager: TableManager = $TableManager
@onready var counter_button: TextureButton = $Counter # Make sure the name matches your Counter node!

# --- ALL TABLE POSITIONS ---
var all_table_positions: Array[Vector2] = [
	Vector2(203.0, 131.0),   # Position for Table #1 (Your Starting Table!)
	Vector2(-115.0, 6.0),    # Position for Table #2
	Vector2(191.0, 6.0),     # Position for Table #3
	Vector2(-157.0, 131.0)   # Position for Table #4
]

func _ready() -> void:
	spawn_all_tables()
	
	if counter_button:
		counter_button.pressed.connect(_on_counter_pressed)
	else:
		print("Controller Error: Could not find the Counter TextureButton!")
		
	if has_node("/root/CustomerManager"):
		CustomerManager.day_completely_cleared.connect(_force_return_to_main)

func spawn_all_tables() -> void:
	var extra_tables_count: int = 3
	
	# --- SMART FALLBACK SYSTEM ---
	if has_node("/root/GameManager"):
		var global_manager = get_node("/root/GameManager")
		if "unlocked_tables_count" in global_manager:
			extra_tables_count = global_manager.unlocked_tables_count
			print("Controller: Connected to global GameManager! Loading ", extra_tables_count, " extra tables.")
	else:
		# Change this to 0, 1, 2, or 3 to test your layouts!
		extra_tables_count = 0 
		print("Controller: No GameManager detected. Running in ISOLATED SCREEN fallback mode.")

	# Always spawn the default starting table (1) PLUS any extra tables bought
	var total_tables_to_spawn = 1 + extra_tables_count 

	for i in range(total_tables_to_spawn):
		if i < all_table_positions.size():
			spawn_table_from_shop(all_table_positions[i], i)

func spawn_table_from_shop(spawn_coord: Vector2, index: int) -> void:
	var table_number = index + 1 # Converts index 0,1,2,3 into Table 1,2,3,4
	var new_table: TableControl
	
	# --- THE LOGIC: SPAWN THE CORRECT ASSET ---
	if table_number == 2 or table_number == 4:
		if not table_flipped_scene:
			print("Controller Error: Missing Flipped Table Asset in Inspector!")
			return
		new_table = table_flipped_scene.instantiate() as TableControl
	else:
		if not table_scene:
			print("Controller Error: Missing Normal Table Asset in Inspector!")
			return
		new_table = table_scene.instantiate() as TableControl
		
	# Name it safely so the Manager can apply the correct scale
	new_table.name = "Table_" + str(table_number) 
	
	# Set position relative to your TablesContainer node's local offset
	new_table.position = spawn_coord
	tables_container.add_child(new_table)
	
	# Hand it over to your TableManager node to be indexed and scaled
	table_manager.register_table(new_table)

# =====================================================================
# CUSTOMER SEATING GATEWAY
# =====================================================================
func request_seat_for_customer() -> Marker2D:
	if table_manager:
		var target_stool = table_manager.find_available_seat()
		if target_stool:
			return target_stool
			
	print("Controller: Seat request failed! No available or clean stools right now.")
	return null
	
# =====================================================================
# SCENE TRANSITIONS (UPDATED FOR GAMEMASTER STACKING)
# =====================================================================
func _on_counter_pressed() -> void:
	print("Counter clicked! Telling GameMaster to return to Main Scene...")
	
	var game_master = get_parent()
	if game_master and game_master.has_method("go_to_main_pov"):
		game_master.go_to_main_pov()
	else:
		print("Controller Error: GameMaster parent not found or missing 'go_to_main_pov' method!")
		
func _force_return_to_main():
	print("Shift over! Telling GameMaster to auto-return to the front counter...")
	
	var game_master = get_parent()
	if game_master and game_master.has_method("go_to_main_pov"):
		game_master.go_to_main_pov()
