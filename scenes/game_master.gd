extends Node

@onready var main_pov = $MainPOV # Replace with the exact name of your Main POV node
@onready var second_pov = $"2nd_pov" # Replace with the exact name of your 2nd POV node

func _ready() -> void:
	# Don't start immediately — wait one frame so everything is fully loaded
	await get_tree().process_frame
	
	# Start the game looking at the Main POV
	go_to_main_pov()
	MusicManager.play_game_music()

func go_to_main_pov() -> void:
	main_pov.visible = true
	# If your scenes use processing/physics, you can also pause the hidden one:
	# main_pov.process_mode = Node.PROCESS_MODE_INHERIT 
	
	second_pov.visible = false
	# second_pov.process_mode = Node.PROCESS_MODE_DISABLED 

func go_to_second_pov() -> void:
	main_pov.visible = false
	second_pov.visible = true
