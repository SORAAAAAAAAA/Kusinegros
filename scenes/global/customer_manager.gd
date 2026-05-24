extends Node

# --- SIGNALS ---
signal live_customer_spawned(id: int)
signal customer_angry_leave(id: int)
signal day_completely_cleared
# --- MENU & SCENES ---
var available_customer_scenes: Array[String] = [
	"res://scenes/customer_scenes/ana.tscn", 
	"res://scenes/customer_scenes/juan.tscn",
	"res://scenes/customer_scenes/clara.tscn",
	"res://scenes/customer_scenes/inengga.tscn",
	"res://scenes/customer_scenes/iniga.tscn",
	"res://scenes/customer_scenes/lullu.tscn",
]
var available_menu: Dictionary = {
	"ulam": ["adobo"],
	"rice": ["rice"] 
} 

# --- MEMORY ---
var active_customers: Dictionary = {}
var next_customer_id: int = 0
var current_spawn_timer: float = 0.0


func _process(delta: float) -> void:
	# 1. THE PATIENCE DRAIN
	if TimeManager.is_shop_open:
		var customers_to_remove = []
		
		for id in active_customers.keys():
			active_customers[id]["patience"] -= delta
			if active_customers[id]["patience"] <= 0:
				customers_to_remove.append(id)
				
		for id in customers_to_remove:
			print("Hostess: Customer ", id, " stormed out!")
			customer_angry_leave.emit(id) 
			active_customers.erase(id)
			
		# 2. THE BACKGROUND SPAWNER
		current_spawn_timer -= delta
		if current_spawn_timer <= 0:
			_try_spawn_background_customer()
		
func add_new_ulam(ulam: String):
	if not available_menu["ulam"].has(ulam):
		available_menu["ulam"].append(ulam)
	else:
		print("Ulam Already available")

# --- FUNCTIONS ---
func reset_for_new_shift():
	active_customers.clear()
	current_spawn_timer = 0.0

func register_new_customer(order: String, max_patience: float, scene_path: String) -> int:
	var id = next_customer_id
	next_customer_id += 1
	active_customers[id] = {
		"order": order, "patience": max_patience, 
		"max_patience": max_patience, "scene_path": scene_path 
	}
	return id

func remove_customer(id: int):
	active_customers.erase(id)

func get_random_order() -> String:
	var chance = randi_range(1, 100)
	if chance <= 33: return available_menu["ulam"].pick_random()
	elif chance <= 66: return "rice"
	else: return available_menu["ulam"].pick_random() + "_rice"

func _try_spawn_background_customer():
	var max_customers = clampi(TimeManager.current_day + 1, 1, 7)
	if active_customers.size() < max_customers:
		if available_customer_scenes.is_empty(): return
		
		var random_path = available_customer_scenes.pick_random()
		var random_order = get_random_order()
		
		var new_id = register_new_customer(random_order, 30.0, random_path)
		live_customer_spawned.emit(new_id)
		
		print("Hostess: Spawned customer ", new_id, " in the background!")
		current_spawn_timer = maxf(8 - (TimeManager.current_day * 0.5), 2.5)
