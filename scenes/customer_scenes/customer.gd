extends TextureRect

@onready var order_bubble = $Visual/OrderBubble
@onready var visuals_node = $Visual
@onready var character_art = $Visual/CustomerArt
@onready var mood_bar = $MoodBar

var play_spawn_animation: bool = false

# --- NEW: QUEUE VARIABLES ---
var in_queue_mode: bool = false 
var my_data: Dictionary # Stores their data so we can hand it to the puppet later

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
var max_patience: float = 30.0 
var my_current_order: String = ""

enum Mood { HAPPY, SEMI, ANGRY }
var current_mood = Mood.HAPPY

func _ready():
	character_art.texture = tex_happy
	
	CustomerManager.customer_angry_leave.connect(_on_global_angry_leave)
	
	if CustomerManager.active_customers.has(my_global_id):
		mood_bar.max_value = CustomerManager.active_customers[my_global_id]["max_patience"]

	# --- 1. SET THE ORDER PICTURE ---
	match my_current_order:
		"rice": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_rice.png")
		"adobo": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_adobo.png") 
		"pastil": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_chicken_pastil.png")
		"menudo": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_menudo.png")
		"cordon": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_cordon_bleu.png")
		"pansit": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_pansit.png")
		"carbonara": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_carbonara.png")
		"mushroom": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_pork_with_mushroom.png")
		"finger": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_chicken_fingers.png")
		"bbq": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_chicken_with_bbq_sauce.png")
		"hamonado": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_only_pork_hamonado.png")
			
		"adobo_rice": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_adobo_rice.png")
		"pastil_rice": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_chicken_pastil_rice.png")
		"cordon_rice": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_cordon_bleu_rice.png")
		"menudo_rice": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_menudo_rice.png")
		"pansit_rice": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_pansit_rice.png")
		"carbonara_rice": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_carbonara_rice.png")
		"mushroom_rice": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_pork_with_mushroom_rice.png")
		"finger_rice": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_chicken_fingers_rice.png")
		"bbq_rice": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_chicken_with_bbq_sauce_rice.png")
		"hamonado_rice": order_bubble.texture = load("res://assets/FOOD ASSETS/plate/plate_pork_hamonado_rice.png")
			
	# --- 2. SPAWN ANIMATION ---
	# Do NOT play the counter bounce if we are in the queue!
	if play_spawn_animation and not in_queue_mode:
		sfx_arrive.play()
		modulate.a = 0.0 
		if visuals_node:
			visuals_node.position.x -= 100.0 
		
		var slide_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		slide_tween.tween_property(self, "modulate:a", 1.0, 0.6)
		if visuals_node:
			slide_tween.tween_property(visuals_node, "position:x", 0.0, 0.6)
			
		if visuals_node:
			var bounce_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			bounce_tween.tween_property(visuals_node, "position:y", -20.0, 0.3) 
			bounce_tween.tween_property(visuals_node, "position:y", 0.0, 0.3)  
	else:
		modulate.a = 1.0
		if visuals_node:
			visuals_node.position = Vector2(0, 0)

# ==========================================
# 2ND POV QUEUE LOGIC
# ==========================================
func setup_and_wait(customer_data: Dictionary) -> void:
	in_queue_mode = true
	my_data = customer_data
	my_global_id = customer_data["id"]
	my_current_order = customer_data["order"]
	
	# Turn off front-counter visuals
	if order_bubble:
		order_bubble.hide()
		
	# Sync patience directly from the brain right away
	if CustomerManager.active_customers.has(my_global_id):
		mood_bar.max_value = CustomerManager.active_customers[my_global_id]["max_patience"]

func advance_in_line(new_spot: Marker2D) -> void:
	# Change parent to the next marker
	reparent(new_spot)
	
	# Smoothly slide them to the new spot (0,0 relative to the marker)
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", Vector2.ZERO, 0.4)

# ==========================================
# FRONT COUNTER LOGIC
# ==========================================
func _can_drop_data(at_position, data):
	# NEW: Do not accept food if standing in the queue!
	if in_queue_mode: return false
	
	if typeof(data) == TYPE_OBJECT and "current_ulam" in data and "has_rice" in data:
		if data.current_ulam != "" or data.has_rice:
			return true
	return false

func _drop_data(at_position, data):
	var plate_contents: String = ""
	
	if data.has_rice and data.current_ulam != "":
		plate_contents = data.current_ulam + "_rice"
	elif data.has_rice:
		plate_contents = "rice"
	elif data.current_ulam != "":
		plate_contents = data.current_ulam
		
	if plate_contents == my_current_order:
		print("Yum! This is exactly what I ordered.")
		var final_payment = 50 
		
		if current_mood == Mood.HAPPY: final_payment += 20 
		elif current_mood == Mood.SEMI: final_payment += 0  
		elif current_mood == Mood.ANGRY: final_payment -= 20 
		
		GameManager.process_successful_sale(my_current_order, final_payment, my_global_id, customer_name)		
		CustomerManager.remove_customer(my_global_id)
		KitchenManager.remove_plate(data.my_plate_index)
	
		data.queue_free() 
		hide() 
		sfx_correct.play()
		await sfx_correct.finished
		queue_free()
	else:
		sfx_wrong.play()
		print("Hey, I ordered ", my_current_order, " not ", plate_contents, "!")
		
func _process(delta):
	if CustomerManager.active_customers.has(my_global_id):
		var time_left = CustomerManager.active_customers[my_global_id]["patience"]
		mood_bar.value = time_left
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
	if id == my_global_id:
		print("Customer left because it took too long!")
		hide()
		if sfx_wrong: 
			sfx_wrong.play()
			await sfx_wrong.finished
		queue_free()
