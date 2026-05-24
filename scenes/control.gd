extends Control

var slides = [
	preload("res://assets/tutorial/slide_1.png"),
	preload("res://assets/tutorial/slide_2.png"),
	preload("res://assets/tutorial/slide_3.png"),
	preload("res://assets/tutorial/slide_5.png"),
	preload("res://assets/tutorial/slide_6.png"),
	preload("res://assets/tutorial/slide_7.png"),
]

var labels = [
	"Welcome to Kabsu Kusineros!\nCustomers will come in and place their orders!",
	"Read Their Orders!\nServe them before their patience bar runs out!",
	"Serve the Right Meal!\nAssemble the correct order by clicking the stack of plates, food tray, and rice cooker.\nDrag the correct plate to the customer to earn coins.",
	"Don't Get It Wrong!\nServing the wrong order costs you coins.\nThrow it in the trash instead!",
	"Watch Your Food and Rice Supply!\nClick the food tray and or rice cooker to refill before customers wait too long!",
	"Manage the Canteen!\nClick the arrow on the right to view the tables.\nClick the dirty table to clean it. If there are no seats, customers will leave!"
]

var current_index = 0

@onready var texture_rect = $TextureRect
@onready var next_button = $Next
@onready var start_button = $Start
@onready var slide_label = $Label 

func _ready():
	# Add dark background to label
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(1, 1, 1, 0.9)
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.content_margin_left = 12
	stylebox.content_margin_right = 12
	stylebox.content_margin_top = 8
	stylebox.content_margin_bottom = 8
	stylebox.border_width_left = 2    # ← black outline
	stylebox.border_width_right = 2
	stylebox.border_width_top = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color(0, 0, 0, 1)  # ← solid black
	slide_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	slide_label.add_theme_stylebox_override("normal", stylebox)
	
	start_button.hide()
	show_slide(0)

func show_slide(index: int):
	texture_rect.texture = slides[index]
	slide_label.text = labels[index]
	
	if index == slides.size() - 1:
		next_button.hide()
		start_button.show()
	else:
		next_button.show()
		start_button.hide()

func _on_next_pressed():
	current_index += 1
	show_slide(current_index)

func _on_start_pressed():
	# Mark tutorial as done
	var f = FileAccess.open("user://tutorial_done.dat", FileAccess.WRITE)
	f.store_string("done")
	f.close()
	
	GameManager.start_new_game()
	get_tree().change_scene_to_file("res://scenes/game_master.tscn")
