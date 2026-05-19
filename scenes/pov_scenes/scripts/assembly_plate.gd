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
	
