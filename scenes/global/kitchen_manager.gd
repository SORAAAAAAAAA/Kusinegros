extends Node

const MAX_PLATES: int = 4

# THE FIX: Change to a Dictionary and track Unique IDs!
var plate_memory: Dictionary = {}
var next_plate_id: int = 0

func reset_kitchen():
	plate_memory.clear()
	next_plate_id = 0
	print("Chef: Counters wiped clean for the new shift!")

# The Chef now returns the unique ID, or -1 if the counter is full!
func register_new_plate() -> int:
	if plate_memory.size() >= MAX_PLATES:
		print("Chef: We don't have enough counter space!")
		return -1 
		
	var id = next_plate_id
	next_plate_id += 1
	plate_memory[id] = "" # Start empty
	
	print("Chef: Registered plate ID ", id, " | Total plates: ", plate_memory.size())
	return id

func save_plate_state(id: int, food_name: String):
	if plate_memory.has(id):
		plate_memory[id] = food_name

func clear_plate(id: int):
	if plate_memory.has(id):
		plate_memory[id] = ""

# NEW: Call this when a plate goes in the trash!
func remove_plate(id: int):
	if plate_memory.has(id):
		plate_memory.erase(id)
		print("Chef: Plate ", id, " thrown away! Remaining plates: ", plate_memory.size())
