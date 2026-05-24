extends TextureButton

# 1. This built-in Godot function asks: "Am I allowed to drop this specific thing here?"
func _can_drop_data(at_position, data):
	# We check if the 'data' we dragged over has the "current_ulam" variable.
	# If it does, we know for a fact it's one of our plates, so we return true!
	if typeof(data) == TYPE_OBJECT and "current_ulam" in data:
		return true
	
	# If they drag something else (like a food tray), reject it.
	return false 

# 2. This built-in Godot function executes when the player releases the mouse button!
func _drop_data(at_position, data):
	# 'data' is the actual plate node we returned in Step 1.
	# We just throw it in the trash by deleting it from the game!
	KitchenManager.remove_plate(data.my_plate_index)
	data.queue_free()
