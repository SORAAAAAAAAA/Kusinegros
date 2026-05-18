extends TextureButton

var has_rice: bool = false
var current_ulam: String = ""

# Textures to swap
@export var tex_empty: Texture2D
@export var tex_rice_only: Texture2D
@export var tex_ulam_only: Texture2D
@export var tex_full: Texture2D

func add_rice():
	has_rice = true
	update_visuals()

func add_ulam(ulam_name: String):
	current_ulam = ulam_name
	update_visuals()

func update_visuals():
	if has_rice and current_ulam != "":
		texture_normal = tex_full
	elif has_rice:
		texture_normal = tex_rice_only
	elif current_ulam != "":
		texture_normal = tex_ulam_only
	else:
		texture_normal = tex_empty

func clear_plate():
	has_rice = false
	current_ulam = ""
	update_visuals()
