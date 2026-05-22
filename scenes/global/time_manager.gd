extends Node

# --- SIGNALS ---
signal time_updated(time_string: String)
signal shift_ended
signal day_changed(new_day: int)

# --- VARIABLES ---
var current_day: int = 1
var shift_duration: float = 90.0 # Real seconds per shift
var time_elapsed: float = 0.0
var is_shop_open: bool = false


func _process(delta: float) -> void:
	if not is_shop_open:
		return
		
	time_elapsed += delta
	
	if time_elapsed >= shift_duration:
		# OUT OF TIME!
		is_shop_open = false
		shift_ended.emit()
		_broadcast_time(1.0) # Force the clock to exactly 5:00 PM
	else:
		# Tell the game exactly what percentage of the day is done
		var percent = time_elapsed / shift_duration
		_broadcast_time(percent)


# Other scripts will call this when they want to wind the clock back to 7:00 AM
func start_new_day():
	time_elapsed = 0.0
	is_shop_open = true
	_broadcast_time(0.0) 
	print("--- DAY ", current_day, " CLOCK STARTED! ---")


# Other scripts will call this to flip the calendar
func advance_to_next_day():
	current_day += 1
	day_changed.emit(current_day)


func _broadcast_time(percent_passed: float):
	var total_shift_minutes = 600.0 
	var in_game_minutes = percent_passed * total_shift_minutes
	var current_time_in_minutes = 420 + in_game_minutes
	
	var hour = int(current_time_in_minutes / 60)
	var minute = int(current_time_in_minutes) % 60
	
	var am_pm = "AM"
	if hour >= 12:
		am_pm = "PM"
		
	var display_hour = hour
	if display_hour > 12:
		display_hour -= 12
	elif display_hour == 0:
		display_hour = 12
		
	var time_string = str(display_hour) + ":" + ("%02d" % minute) + " " + am_pm
	time_updated.emit(time_string)
