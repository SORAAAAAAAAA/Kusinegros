extends Control

@onready var sfx_clicked = $SfxClicked
@onready var fade_overlay = $FadeOverlay

# Store the path here so we don't have to retype it multiple times!
var target_scene_path = "res://scenes/pov_scenes/main_pov.tscn"


func _ready() -> void:
	# Keep the process loop turned off until we actually need to load something
	set_process(false)


func _process(delta):
	# This function only wakes up AFTER the screen has faded to black.
	# Check how far along the background loading is:
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		# The scene is still loading. 
		# You can print(progress[0]) here if you want to see the percentage (0.0 to 1.0)
		pass
		
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		# It's 100% done! Grab the packed scene from the background thread.
		var next_scene = ResourceLoader.load_threaded_get(target_scene_path)
		
		# Swap to the new scene and put the process loop back to sleep.
		get_tree().change_scene_to_packed(next_scene)
		set_process(false)
		
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		print("Error: Failed to load the scene in the background.")
		set_process(false)


func _on_new_button_pressed() -> void:
	# 1. PREVENT DOUBLE-CLICKS & PLAY SOUND
	$NewButton.disabled = true
	sfx_clicked.play()
	
	# 2. RESET GAME DATA (Clean Slate)
	GameManager.current_day = 1
	GameManager.money = 0
	
	# 3. KICK OFF THE BACKGROUND LOAD INSTANTLY
	# We tell the engine to start fetching the heavy data in the background 
	# right now, while our Main Thread handles the UI fade-out.
	ResourceLoader.load_threaded_request(target_scene_path)
	
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
	sfx_clicked.play()
	# You will use the exact same background loading logic here later, 
	# but instead of resetting GameManager data, you will load it from a save file!


func _on_settings_button_pressed() -> void:
	sfx_clicked.play()
	# opens the settings menu
