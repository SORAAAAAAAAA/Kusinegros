extends TextureButton

@export var max_portions: int = 16 # Rice usually has more servings than ulam!

# --- The 4 Visual States ---
@export var tex_full: Texture2D
@export var tex_half: Texture2D
@export var tex_empty: Texture2D
@export var tex_cooking: Texture2D 

var portions_left: int
var is_cooking: bool = false

@onready var cook_timer = $CookingTimer
@onready var cook_bar = $CookingBar

func _ready():
	portions_left = max_portions
	cook_bar.hide()
	update_visuals()
	
func _on_pressed():
	var plates = get_node("/root/MainPOV/GridContainerPlates").get_children()

	if is_cooking: 
		return
		
	if plates.is_empty():
		print("No plates yet...")
		return
		
	if portions_left > 0:
		# Loop through all dynamically spawned plates in the grid
		for plate in plates:
			# Find the first plate that needs rice
			if not plate.has_rice:
				plate.add_rice()
				portions_left -= 1
				update_visuals()
				
				# Start cooking automatically when it runs out
				if portions_left <= 0:
					start_cooking()
					
				# IMPORTANT: Stop the loop so we only add rice to ONE plate per click!
				return 
	else:
		# Failsafe: if it's empty and not cooking, click to start
		start_cooking()

func update_visuals():
	# Priority 1: Is it cooking? Show the closed, steaming pot.
	if is_cooking:
		texture_normal = tex_cooking
	# Priority 2: 9-16 portions
	elif portions_left > (max_portions / 2):
		texture_normal = tex_full
	# Priority 3: 1 to 5 portions
	elif portions_left > 0:
		texture_normal = tex_half
	# Priority 4: 0 portions (open pot, completely empty)
	else:
		texture_normal = tex_empty

func start_cooking():
	is_cooking = true
	update_visuals() # This triggers the steaming rice cooker graphic
	
	cook_bar.show()
	cook_bar.max_value = 5.0 # Rice takes a bit longer to cook!
	cook_timer.start(5.0)

func _process(_delta):
	if is_cooking:
		cook_bar.value = 5.0 - cook_timer.time_left

func _on_cooking_timer_timeout():
	portions_left = max_portions
	is_cooking = false
	cook_bar.hide()
	update_visuals() # Pops open to reveal the full rice!
