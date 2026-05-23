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
	if portions_left <= 0 and is_refilling == false:
		start_refill()
		return
		
	# THE FIX: Bulletproof relative path!
	# ".." goes up to GridContainerFood, the second ".." goes up to MainPOV.
	var plate_container = get_node("../../GridContainerPlates")
	
	if not plate_container:
		print("Error: Could not find GridContainerPlates!")
		return
		
	var plates = plate_container.get_children()
	
	for plate in plates:
		# Find the first plate that doesn't have an ulam yet
		if "current_ulam" in plate and plate.current_ulam == "":
			plate.add_ulam(food_name)
			portions_left -= 1
			update_tray_visuals()
			
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
	refill_bar.show()
	refill_bar.max_value = 3.0 
	refill_timer.start(3.0)
	update_tray_visuals() 

func _process(_delta):
	if is_refilling:
		refill_bar.value = 3.0 - refill_timer.time_left

func _on_refill_timer_timeout():
	portions_left = max_portions
	is_refilling = false
	refill_bar.hide()
	update_tray_visuals() # Switches back to the full texture
