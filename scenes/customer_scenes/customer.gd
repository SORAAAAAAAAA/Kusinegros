extends TextureRect

@onready var order_bubble = $Visual/OrderBubble
@onready var visuals_node = $Visual
@onready var character_art = $Visual/CustomerArt
@onready var mood_bar = $MoodBar

var play_spawn_animation: bool = false

# --- MOOD TEXTURES ---
@export var customer_name: String
@export var tex_happy: Texture2D
@export var tex_semi_happy: Texture2D
@export var tex_angry: Texture2D

# --- AUDIO ---
@onready var sfx_arrive = $SfxArrive
@onready var sfx_correct = $SfxCorrect
@onready var sfx_wrong = $SfxWrong

# --- PATIENCE SYSTEM (MVC UPDATED) ---
var my_global_id: int = -1 
var max_patience: float = 30.0 # Customer will wait 30 seconds total
var my_current_order: String = ""

# Track the current state so we don't update the texture every single frame
enum Mood { HAPPY, SEMI, ANGRY }
var current_mood = Mood.HAPPY


func _ready():
	character_art.texture = tex_happy
	
	# THE MVC UPGRADE: We are now a 100% Pure Puppet. 
	# The GameManager already created our ID and Order before we spawned!
	
	# Connect signals and grab max value from the brain
	CustomerManager.customer_angry_leave.connect(_on_global_angry_leave)
	
	if CustomerManager.active_customers.has(my_global_id):
		mood_bar.max_value = CustomerManager.active_customers[my_global_id]["max_patience"]


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
		"pansit":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_pansit.png")
		"carbonara":	
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_carbonara.png")
		"mushroom":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_pork_with_mushroom.png")
		"finger":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_chicken_fingers.png")
		"bbq":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_chicken_with_bbq_sauce.png")
		"hamonado":	
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_pork_hamonado.png")
			
		# --- COMBO MEALS ---
		"adobo_rice":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_adobo_rice.png")
		"pastil_rice":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_chicken_pastil_rice.png")
		"cordon_rice":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_cordon_bleu_rice.png")
		"menudo_rice":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_menudo_rice.png")
		"pansit_rice":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_pansit_rice.png")
		"carbonara_rice":
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_carbonara_rice.png")
		"mushroom_rice":	
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_pork_with_mushroom_rice.png")
		"finger_rice":	
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_chicken_fingers_rice.png")
		"bbq_rice":	
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_chicken_with_bbq_sauce_rice.png")
		"hamonado_rice":	
			order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_pork_hamonado_rice.png")
			

	# --- 2. SPAWN ANIMATION ---
	# We rely entirely on the boolean passed down by main_pov.gd!
	if play_spawn_animation:
		sfx_arrive.play()
		modulate.a = 0.0 
		if visuals_node:
			visuals_node.position.x -= 100.0 # Start left
		
		# Tween 1: The Slide and Fade
		var slide_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		slide_tween.tween_property(self, "modulate:a", 1.0, 0.6)
		if visuals_node:
			slide_tween.tween_property(visuals_node, "position:x", 0.0, 0.6)
			
		# Tween 2: The "Step" Bounce
		if visuals_node:
			var bounce_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			bounce_tween.tween_property(visuals_node, "position:y", -20.0, 0.3) 
			bounce_tween.tween_property(visuals_node, "position:y", 0.0, 0.3)  
	else:
		# They were already here! Snap them directly to their final visible position instantly.
		modulate.a = 1.0
		if visuals_node:
			visuals_node.position = Vector2(0, 0)


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
		# It's a combo! Combine them
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
		GameManager.process_successful_sale(my_current_order, final_payment, my_global_id)
		
		# THE MVC UPGRADE: Tell the brain we have been fed!
		CustomerManager.remove_customer(my_global_id)
		KitchenManager.remove_plate(data.my_plate_index)
	
		# 1. Delete the plate so it doesn't linger
		data.queue_free() 
		
		# 2. Instantly hide the customer so it looks like they left
		hide() 
		
		# 3. Play the success sound
		sfx_correct.play()
		
		# 4. Wait for the sound to finish playing!
		await sfx_correct.finished
		
		# 5. Now it's safe to delete the customer permanently
		queue_free()
	else:
		sfx_wrong.play()
		print("Hey, I ordered ", my_current_order, " not ", plate_contents, "!")
		
func _process(delta):
	if CustomerManager.active_customers.has(my_global_id):
		var time_left = CustomerManager.active_customers[my_global_id]["patience"]
		
		# Force the progress bar to match the brain
		mood_bar.value = time_left
		
		# Pass the brain's time to our visual mood checker
		check_mood_change(time_left)


func check_mood_change(time_left: float):
	var percentage_left = time_left / max_patience
	
	if percentage_left > 0.6 and current_mood != Mood.HAPPY:
		current_mood = Mood.HAPPY
		character_art.texture = tex_happy 
		
	elif percentage_left <= 0.6 and percentage_left > 0.3 and current_mood != Mood.SEMI:
		current_mood = Mood.SEMI
		character_art.texture = tex_semi_happy 
		
	elif percentage_left <= 0.3 and current_mood != Mood.ANGRY:
		current_mood = Mood.ANGRY
		character_art.texture = tex_angry 


func _on_global_angry_leave(id: int):
	# Check if the brain is talking to ME
	if id == my_global_id:
		print("Customer left because it took too long!")
		hide()
		if sfx_wrong: 
			sfx_wrong.play()
			await sfx_wrong.finished
		queue_free()
