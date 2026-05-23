extends Node

# 1. Create the physical speaker
var audio_player = AudioStreamPlayer.new()

# 2. Add your music files here! 
var menu_music = preload("res://assets/OTHER UI-ASSETS/audio/main_menu_bg_music.mp3")
var game_music = preload("res://assets/OTHER UI-ASSETS/audio/in_game_bg_music.mp3")

func _ready():
	# Plug the speaker into the engine when the game starts
	add_child(audio_player)
	
	# Set the volume (Optional: -10.0 decibels makes it quieter so it doesn't blast the player's ears)
	audio_player.volume_db = -10.0

func play_menu_music():
	# Check if it's already playing the menu music! 
	if audio_player.stream == menu_music and audio_player.playing:
		return
		
	audio_player.stream = menu_music
	audio_player.play()
	print("DJ: Now playing Main Menu music!")

func play_game_music():
	# Check if the game music is already playing
	if audio_player.stream == game_music and audio_player.playing:
		return
		
	audio_player.stream = game_music
	audio_player.play()
	print("DJ: Now playing Kitchen music!")

func stop_music():
	audio_player.stop()
