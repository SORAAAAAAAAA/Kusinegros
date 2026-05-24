extends Node
class_name TableManager

# A master array to keep track of every table currently active in the room
var active_tables: Array[TableControl] = []

# Reference to the container where all our tables live
@onready var tables_container: Control = $"../TablesContainer"

func _ready() -> void:
	# Wait one frame to ensure all child tables have finished running their own _ready() loops
	await get_tree().process_frame
	register_initial_tables()

func register_initial_tables() -> void:
	if tables_container:
		for child in tables_container.get_children():
			if child is TableControl:
				register_table(child)
	else:
		print("TableManager Error: TablesContainer node could not be found!")

func register_table(table: TableControl) -> void:
	if table not in active_tables:
		active_tables.append(table)
		
		# --- 1. OVERLAP FIX (Z-INDEX Y-SORTING) ---
		# This perfectly layers the tables so front tables draw over back tables!
		table.z_index = int(table.global_position.y)
		
		# --- 2. MANUAL SCALING ---
		apply_manual_scale(table)
		
		# Connect to the table's cleaning signal
		table.table_cleaned.connect(_on_table_cleaned)

# =====================================================================
# MANUAL SCALING EDITOR
# =====================================================================
func apply_manual_scale(table: TableControl) -> void:
	
	# --- BASE SIZE ---
	# This represents your main Table 1 size. 
	# If ALL the tables feel slightly too big or too small, change this 1.0!
	var base_size: float = 1.0 
	
	# CHECKING THE NEW CORRECT NAMES!
	if "Table_1" in table.name:
		print("TableManager: Scaling Table 1")
		table.scale = Vector2(base_size * 0.7, base_size * 0.7)
		
	elif "Table_2" in table.name:
		print("TableManager: Scaling Table 2")
		# Your 0.5 size!
		table.scale = Vector2(base_size * 0.6, base_size * 0.6)
		
	elif "Table_3" in table.name:
		print("TableManager: Scaling Table 3")
		# Your 0.6 size!
		table.scale = Vector2(base_size * 0.6, base_size * 0.6)
		
	elif "Table_4" in table.name:
		print("TableManager: Scaling Table 4")
		# Your 0.7 size!
		table.scale = Vector2(base_size * 0.7, base_size * 0.7)
		
	else:
		print("TableManager WARNING: Unknown table registered - ", table.name)

# =====================================================================
# SEATING LOGIC
# =====================================================================
func find_available_seat() -> Marker2D:
	for table in active_tables:
		# Students completely ignore dirty tables
		if table.current_state != TableControl.State.DIRTY:
			# If there is an open stool, grab it!
			if table.available_seats.size() > 0:
				var assigned_seat_marker = table.claim_a_seat()
				return assigned_seat_marker
				
	return null

func _on_table_cleaned(table: TableControl) -> void:
	print("TableManager: Received cleaning notification from ", table.name)
