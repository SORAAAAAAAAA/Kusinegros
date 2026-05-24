extends Control

@onready var sfx_clicked = $SfxClicked
@onready var fade_overlay = $FadeOverlay
@onready var volume_slider = %VolumeSlider
@onready var settings_overlay = %SettingsOverlay

# Store the path here so we don't have to retype it multiple times!
var target_scene_path = "res://scenes/tutorial.tscn"
var continue_scene_path = "res://scenes/game_master.tscn"
var active_target_path = ""
var master_bus_index: int
@onready var continue_button = %ContinueButton
@onready var new_game_button = %NewButton

func _ready() -> void:
	MusicManager.play_menu_music()
	# Keep the process loop turned off until we actually need to load something
	set_process(false)
	settings_overlay.hide()
	master_bus_index = AudioServer.get_bus_index("Master")
	
	if SaveManager.has_save_file():
		continue_button.disabled = false
	else:
		continue_button.disabled = true # Grey it out so they can't click it!


func _process(delta):
	# This function only wakes up AFTER the screen has faded to black.
	# Check how far along the background loading is:
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(active_target_path, progress)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		# The scene is still loading. 
		# You can print(progress[0]) here if you want to see the percentage (0.0 to 1.0)
		pass
		
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		# It's 100% done! Grab the packed scene from the background thread.
		var next_scene = ResourceLoader.load_threaded_get(active_target_path)
		
		# Swap to the new scene and put the process loop back to sleep.
		get_tree().change_scene_to_packed(next_scene)
		set_process(false)
		
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		print("Error: Failed to load the scene in the background.")
		set_process(false)


func _on_new_button_pressed() -> void:
	# Check if tutorial was already seen
	if FileAccess.file_exists("user://tutorial_done.dat"):
		active_target_path = "res://scenes/game_master.tscn"
	else:
		active_target_path = target_scene_path
	
	# 1. PREVENT DOUBLE-CLICKS & PLAY SOUND
	$NewButton.disabled = true
	sfx_clicked.play()
	
	# Clear tutorial flag so new game always shows tutorial
	if FileAccess.file_exists("user://tutorial_done.dat"):
		DirAccess.remove_absolute("user://tutorial_done.dat")
	
	# 3. KICK OFF THE BACKGROUND LOAD INSTANTLY
	# We tell the engine to start fetching the heavy data in the background 
	# right now, while our Main Thread handles the UI fade-out.
	ResourceLoader.load_threaded_request(active_target_path)
	
	# 4. START THE VISUAL FADE
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.5)
	
	# 5. WAIT FOR THE VISUALS TO FINISH
	# (Because this takes 0.8 seconds, we no longer need the 0.1s timer! 
	# The sound has plenty of time to play.)
	await tween.finished
	
	# 6. TURN ON THE PROCESS LOOP
	# The screen is now completely black. We wake up the _process function 
	# to check if the background loading finished while we were fading.
	set_process(true)


func _on_continue_button_pressed() -> void:
	active_target_path = continue_scene_path
	$ContinueButton.disabled = true
	sfx_clicked.play()
	# 1. Tell the Archivist to inject the saved data into the Managers
	SaveManager.load_game()
	
	# 2. Load into the game!
	ResourceLoader.load_threaded_request(continue_scene_path)
	
	# 4. START THE VISUAL FADE
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.5)
	
	# 5. WAIT FOR THE VISUALS TO FINISH
	# (Because this takes 0.8 seconds, we no longer need the 0.1s timer! 
	# The sound has plenty of time to play.)
	await tween.finished
	
	# 6. TURN ON THE PROCESS LOOP
	# The screen is now completely black. We wake up the _process function 
	# to check if the background loading finished while we were fading.
	set_process(true)


func _on_settings_button_pressed() -> void:
	sfx_clicked.play()
	settings_overlay.show()
	# opens the settings menu


# 3. THE VOLUME SLIDER LOGIC
func _on_volume_slider_value_changed(value: float) -> void:
	# Translate the 0.0 - 1.0 slider value into Decibels using linear_to_db,
	# and apply it to the Master audio bus!
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))
	
	# Optional: Play a sound effect every time they drag the slider so they can hear the change!
	if not sfx_clicked.playing:
		sfx_clicked.play()


func _on_back_button_pressed() -> void:
	settings_overlay.hide()

	sfx_clicked.play()
