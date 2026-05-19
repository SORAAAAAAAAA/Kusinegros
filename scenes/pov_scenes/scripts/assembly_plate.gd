extends TextureButton

var has_rice: bool = false
var current_ulam: String = ""

# Textures to swap
@export var tex_empty: Texture2D
@export var tex_rice_only: Texture2D

@export var ulam_only_textures: Dictionary = {}
@export var full_plate_textures: Dictionary = {}

func _ready():
	# Always start empty
	texture_normal = tex_empty

func add_rice():
	if has_rice:
		return
	has_rice = true
	update_visuals()

func add_ulam(ulam_name: String):
	if current_ulam != "":
		return
	current_ulam = ulam_name
	update_visuals()

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

func clear_plate():
	has_rice = false
	current_ulam = ""
	update_visuals()

# This built-in Godot function triggers automatically when you click and drag this UI node
func _get_drag_data(at_position):
	# 1. Create a visual preview (the "ghost" image that follows the mouse)
	var preview_texture = TextureRect.new()
	preview_texture.texture = texture_normal # Copy whatever the plate currently looks like!
	
	# Keep the preview the exact same size as the real plate
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.custom_minimum_size = size 
	
	# 2. Center the ghost image exactly on the mouse cursor
	var preview_control = Control.new()
	preview_control.add_child(preview_texture)
	preview_texture.position = -0.5 * size 
	
	# Tell Godot to use this as the drag visual
	set_drag_preview(preview_control)
	texture_normal = null
	
	# 3. Return 'self'. This passes the actual plate node data to the Trash Bin!
	return self
