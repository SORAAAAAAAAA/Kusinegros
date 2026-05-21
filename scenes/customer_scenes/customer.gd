extends TextureRect

@onready var order_bubble = $Visual/OrderBubble
@onready var visuals_node = $Visual
@onready var character_art = $Visual/CustomerArt

# --- MOOD TEXTURES ---
@export var customer_name: String
@export var tex_happy: Texture2D
@export var tex_semi_happy: Texture2D
@export var tex_angry: Texture2D

# --- PATIENCE SYSTEM ---
var max_patience: float = 30.0 # Customer will wait 30 seconds total
var current_patience: float

var my_current_order: String = ""

# Track the current state so we don't update the texture every single frame
enum Mood { HAPPY, SEMI, ANGRY }
var current_mood = Mood.HAPPY


func _ready():
	character_art.texture = tex_happy
	current_patience = max_patience
	my_current_order = GameManager.get_random_order()
	print("New customer arrived! They want: ", my_current_order)
	
	# --- 1. SET THE ORDER PICTURE ---
	match my_current_order:
		# --- SOLO ITEMS ---
		"rice":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_rice.png")
		"adobo":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_adobo.png") 
		"pastil":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_chicken_pastil.png")
		"menudo":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_menudo.png")
		"cordon":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_cordon_bleu.png")
		"sisig":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_sisig.png")
		"pansit":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_pansit.png")
			
		# --- COMBO MEALS ---
		"adobo_rice":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_adobo_rice.png") # Load your combo plate!
		"pastil_rice":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_chicken_pastil_rice.png")
		"cordon_rice":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_cordon_bleu_rice.png")
		"menudo_rice":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_menudo_rice.png")
		"pansit_rice":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_pansit_rice.png")
		"sisig_rice":	
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_sisig_rice.png")
	
	# --- 2. SPAWN ANIMATION (SLIDE & BOUNCE) ---
	modulate.a = 0.0 
	
	if visuals_node:
		visuals_node.position.x -= 100.0 # Start left
	
	# Tween 1: The Slide and Fade (happens together)
	var slide_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide_tween.tween_property(self, "modulate:a", 1.0, 0.6)
	if visuals_node:
		slide_tween.tween_property(visuals_node, "position:x", 0.0, 0.6)
		
	# Tween 2: The "Step" Bounce (Up then Down)
	if visuals_node:
		var bounce_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bounce_tween.tween_property(visuals_node, "position:y", -20.0, 0.3) # Hop up slightly
		bounce_tween.tween_property(visuals_node, "position:y", 0.0, 0.3)  # Land back down

# 2. Am I allowed to drop something on this customer?
func _can_drop_data(at_position, data):
	# Make sure it's a plate by checking for our variables
	if typeof(data) == TYPE_OBJECT and "current_ulam" in data and "has_rice" in data:
		# Allow the drop if it has either ulam OR rice (or both!)
		if data.current_ulam != "" or data.has_rice:
			return true
	return false

# 3. What happens when the plate is dropped on ME?
func _drop_data(at_position, data):
	
	# --- TRANSLATE THE PLATE'S STATE INTO A STRING ---
	var plate_contents: String = ""
	
	if data.has_rice and data.current_ulam != "":
		# It's a combo! Combine them (e.g., "adobo" + "_rice" = "adobo_rice")
		plate_contents = data.current_ulam + "_rice"
	elif data.has_rice:
		# It's just rice
		plate_contents = "rice"
	elif data.current_ulam != "":
		# It's just ulam
		plate_contents = data.current_ulam
		
		
	# --- CHECK IF IT MATCHES ---
	if plate_contents == my_current_order:
		print("Yum! This is exactly what I ordered.")
		
		# Calculate payment based on mood
		var final_payment = 50 # Base price
		
		if current_mood == Mood.HAPPY:
			final_payment += 20 # Nice tip! (70 total)
		elif current_mood == Mood.SEMI:
			final_payment += 0  # No tip (50 total)
		elif current_mood == Mood.ANGRY:
			final_payment -= 20 # Angry discount (30 total)
		
		# Tell the GameManager to process the sale with our new total
		GameManager.process_successful_sale(my_current_order, final_payment)
		
		data.queue_free() # Delete the plate
		queue_free()  # Delete the customer
	else:
		# They reject it! Notice we use 'plate_contents' here so the console 
		# prints exactly what the player gave them.
		print("Hey, I ordered ", my_current_order, " not ", plate_contents, "!")
		# We DO NOT delete the plate here, so the player gets it back!

func _process(delta):
	# Decrease patience over time
	if current_patience > 0:
		current_patience -= delta
		check_mood_change()
	else:
		# Time ran out!
		walk_out_angry()

func check_mood_change():
	var percentage_left = current_patience / max_patience
	
	if percentage_left > 0.6 and current_mood != Mood.HAPPY:
		current_mood = Mood.HAPPY
		character_art.texture = tex_happy # UPDATED
		
	elif percentage_left <= 0.6 and percentage_left > 0.3 and current_mood != Mood.SEMI:
		current_mood = Mood.SEMI
		character_art.texture = tex_semi_happy # UPDATED
		print("Customer is getting impatient!")
		
	elif percentage_left <= 0.3 and current_mood != Mood.ANGRY:
		current_mood = Mood.ANGRY
		character_art.texture = tex_angry # UPDATED
		print("Customer is furious!")

func walk_out_angry():
	print("Customer left because it took too long!")
	# Optional: You could deduct money here using GameManager.money -= 20
	queue_free()
