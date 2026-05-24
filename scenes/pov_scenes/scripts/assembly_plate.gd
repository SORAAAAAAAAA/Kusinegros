extends TextureButton


# Change this in the Godot Inspector! (Left Plate = 0, Middle = 1, Right = 2)
@export var my_plate_index: int = 0

var has_rice: bool = false
var current_ulam: String = ""

# Textures to swap
@export var tex_empty: Texture2D
@export var tex_rice_only: Texture2D

@export var ulam_only_textures: Dictionary = {}
@export var full_plate_textures: Dictionary = {}

var saved_texture: Texture2D

func _ready():
	# Always start empty
	texture_normal = tex_empty


# =====================================================================
# ADDING FOOD (Player Actions)
# =====================================================================

func add_rice():
	if has_rice:
		return
	has_rice = true
	update_visuals()
	_report_to_chef() # Tell the Autoload!

func add_ulam(ulam_name: String):
	if current_ulam != "":
		return
	current_ulam = ulam_name
	update_visuals()
	_report_to_chef() # Tell the Autoload!

func clear_plate():
	has_rice = false
	current_ulam = ""
	update_visuals()
	KitchenManager.clear_plate(my_plate_index) # Tell the Autoload!


# =====================================================================
# THE CHEF COMMUNICATION (New Architecture)
# =====================================================================

func _report_to_chef():
	# Translate our local variables into a single string for the memory bank
	var food_string = ""
	
	if has_rice and current_ulam != "":
		food_string = current_ulam + "_rice"
	elif has_rice:
		food_string = "rice"
	elif current_ulam != "":
		food_string = current_ulam
		
	# Save it to the global memory
	KitchenManager.save_plate_state(my_plate_index, food_string)


# main_pov.gd will call this function to rebuild the plate when switching cameras!
func add_food_to_plate(food_string: String):
	# Parse the string backward into our local variables
	if food_string == "rice":
		has_rice = true
	elif food_string.ends_with("_rice"):
		has_rice = true
		current_ulam = food_string.replace("_rice", "")
	else:
		current_ulam = food_string
		
	update_visuals()


# =====================================================================
# VISUALS & DRAG LOGIC (Untouched!)
# =====================================================================

func update_visuals():
	if has_rice and current_ulam != "":
		# Check if our dictionary has a full plate image for this specific ulam
		if full_plate_textures.has(current_ulam):
			texture_normal = full_plate_textures[current_ulam]
		else:
			print("WARNING: No full plate texture found for ", current_ulam)
			
	elif has_rice:
		texture_normal = tex_rice_only
		
	elif current_ulam != "":
		# Check if our dictionary has an ulam-only plate image
		if ulam_only_textures.has(current_ulam):
			texture_normal = ulam_only_textures[current_ulam]
		else:
			print("WARNING: No ulam-only texture found for ", current_ulam)
			
	else:
		texture_normal = tex_empty


func _get_drag_data(at_position):
	# 1. Create a visual preview (the "ghost" image that follows the mouse)
	var preview_texture = TextureRect.new()
	preview_texture.texture = texture_normal # Copy the plate's current look
	
	# Keep the preview the exact same size as the real plate
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.custom_minimum_size = size 
	
	# 2. Center the ghost image exactly on the mouse cursor
	var preview_control = Control.new()
	preview_control.add_child(preview_texture)
	preview_texture.position = -0.5 * size 
	
	# Tell Godot to use this as the drag visual
	set_drag_preview(preview_control)
	
	# 3. THE BULLETPROOF TRICK:
	modulate.a = 0.0
	
	# 4. Return 'self' to pass the actual plate node data
	return self
	
func _notification(what):
	# This triggers the exact moment the user releases the mouse button
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0
