extends TextureButton

# Drag your assembly_plate.tscn file from the FileSystem into this slot in the Inspector!
@export var plate_scene: PackedScene 

@onready var plate_grid = $"../GridContainerPlates" # Adjust this path if necessary

func _on_plate_stack_button_pressed():
	# Check if we already have 4 plates (a 2x2 grid full)
	if plate_grid.get_child_count() >= 4:
		print("Grid is full! Cannot spawn more plates.")
		return
		
	# Instantiate the plate and add it to the grid
	var new_plate = plate_scene.instantiate()
	plate_grid.add_child(new_plate)
	print("Spawned a new empty plate!")
