extends Node2D

@onready var customer_art = $CustomerArt 
@onready var eating_timer = $EatingTimer

var my_data: Dictionary
var walk_speed: float = 150.0 
var identity: String = "ana" 

func _ready():
	eating_timer.timeout.connect(_on_finished_eating)

# Called by the 2nd_pov_controller during direct seating OR the handoff
func setup_and_seat(customer_data: Dictionary) -> void:
	my_data = customer_data
	
	if my_data.has("name") and my_data["name"] != "":
		identity = my_data["name"].to_lower()
		
	_walk_to_seat()

func _walk_to_seat() -> void:
	z_index = 100
	
	# We are a child of the stool, so the target is our parent's global position
	var target_global_pos = get_parent().global_position
	var distance = global_position.distance_to(target_global_pos)
	
	var travel_time = 0.0
	if distance > 1.0:
		travel_time = distance / walk_speed
	
	# FACE THE CORRECT DIRECTION
	if target_global_pos.x < global_position.x:
		customer_art.flip_h = true 
	else:
		customer_art.flip_h = false
		
	# PLAY THE WALK ANIMATION
	if customer_art.has_method("play"):
		customer_art.play(identity + "_walk")
	
	if travel_time > 0:
		var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
		# We tween local position to ZERO because we are a child of the stool marker
		tween.tween_property(self, "position", Vector2.ZERO, travel_time)
		tween.tween_callback(_start_eating)
	else:
		_start_eating()

func _start_eating() -> void:
	z_index = 0
	print(identity + " arrived at table! Starting to eat.")
	
	# PLAY THE SITTING ANIMATION
	if customer_art.has_method("play"):
		customer_art.play(identity + "_sit") 
	
	eating_timer.start(7.0)

func _on_finished_eating() -> void:
	print(identity + " finished eating. Leaving!")
	
	# Tell the table to mark itself as dirty
	var table = get_parent().get_parent().get_parent() # Stool Marker -> Stools Folder -> Table
	if table.has_method("report_customer_finished"):
		table.report_customer_finished()
		
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)
