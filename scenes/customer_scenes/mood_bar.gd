extends TextureProgressBar

signal time_ran_out

var max_time: float = 0.0
var current_time: float = 0.0
var is_running: bool = false

# --- 1. THE STARTUP COMMAND ---
func start_timer(time_in_seconds: float):
	step = 0.01 
	max_time = time_in_seconds
	current_time = time_in_seconds
	max_value = max_time
	value = current_time 
	is_running = true

# --- 2. THE INTERNAL CLOCK ---
func _process(delta):
	if not is_running: 
		return
		
	if current_time > 0:
		current_time -= delta
		
		# Because the node is a TextureProgressBar, lowering the value 
		# automatically clips the Green side of the texture away!
		value = current_time 
	else:
		is_running = false
		time_ran_out.emit()
