extends TextureButton

@export var plate_scene: PackedScene 

@onready var plate_grid = $"../GridContainerPlates" 
@onready var sfx_plate = $"../SfxPlate"

func _on_plate_stack_button_pressed():
	if sfx_plate:
		sfx_plate.play()
		
	# 1. Ask the Chef for an ID! (Returns -1 if full)
	var new_id = KitchenManager.register_new_plate()
	
	if new_id != -1:
		# 2. If the Chef gave us a valid ID, build it!
		var new_plate = plate_scene.instantiate()
		
		# Give it the exact ID the Chef generated!
		new_plate.my_plate_index = new_id
		
		plate_grid.add_child(new_plate)
		print("UI: Spawned Plate ID: ", new_plate.my_plate_index)
	else:
		print("UI: The Chef said the grid is full. Ignoring click.")
