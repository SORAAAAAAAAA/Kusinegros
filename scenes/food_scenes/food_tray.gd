extends TextureButton

@export var food_name: String = ""
@export var max_portions: int = 8

# --- NEW: Texture slots for the Inspector ---
@export var tex_full: Texture2D
@export var tex_half: Texture2D
@export var tex_empty: Texture2D

var portions_left: int
var is_refilling: bool = false

@onready var refill_timer = $RefillTimer
@onready var refill_bar = $RefillBar


func _ready():
	portions_left = max_portions
	refill_bar.hide()
	update_tray_visuals() # Set the initial graphic
	
func _on_pressed():
	# Look at all the plates currently in the grid
	var plates = get_node("/root/MainPOV/GridContainerPlates").get_children()
	
	if is_refilling or portions_left <= 0: 
		return
	
	for plate in plates:
		# Find the first plate that doesn't have an ulam yet
		if plate.current_ulam == "":
			plate.add_ulam(food_name)
			portions_left -= 1
			update_tray_visuals()
			
			if portions_left <= 0:
				start_refill()
			
			return # Stop looping once we found a plate!

# --- NEW: Logic to determine which sprite to show ---
func update_tray_visuals():
	if portions_left > (max_portions / 2): # e.g., 5, 4, 3 portions left
		texture_normal = tex_full
	elif portions_left > 0:                # e.g., 2, 1 portions left
		texture_normal = tex_half
	else:                                  # 0 portions left
		texture_normal = tex_empty

func start_refill():
	is_refilling = true
	update_tray_visuals() # Will set it to the empty texture
	
	refill_bar.show()
	refill_bar.max_value = 3.0 
	refill_timer.start(3.0)

func _process(_delta):
	if is_refilling:
		refill_bar.value = 3.0 - refill_timer.time_left

func _on_refill_timer_timeout():
	portions_left = max_portions
	is_refilling = false
	refill_bar.hide()
	update_tray_visuals() # Switches back to the full texture
