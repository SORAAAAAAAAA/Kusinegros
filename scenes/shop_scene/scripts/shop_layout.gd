extends CanvasLayer

signal shop_closed

# ── Colors (card hover/press only — buy button states are in upgrade_card.tscn) ──
const COLOR_CARD_BG    := Color(0.118, 0.235, 0.165, 1.0)
const COLOR_CARD_HOVER   := Color(0.165, 0.310, 0.220, 1.0)
const COLOR_CARD_PRESSED := Color(0.078, 0.157, 0.110, 1.0)

# ── Upgrade data ───────────────────────────────────────────────────────────────
var current_tab   := "ulam"
var selected_card := -1

var ulam_upgrades := [
	{"id": "cordon",    "name": "Cordon Bleu",      "desc": "Breaded pork stuffed\nwith ham and cheese",     "price": 150,  "image": "res://assets/FOOD ASSETS/shop/cordon_bleu.png"},	
	{"id": "mushroom",  "name": "Pork Mushroom",    "desc": "Tender pork strips\nwith creamy mushroom",      "price": 200,  "image": "res://assets/FOOD ASSETS/shop/pork_mushroom.png"},
	{"id": "hamonado",  "name": "Pork Hamonado",    "desc": "Sweet pork braised\nin pineapple sauce",        "price": 250, "image": "res://assets/FOOD ASSETS/shop/pork_hamonado.png"},
	{"id": "pansit",    "name": "Pansit",           "desc": "Stir-fried noodles\nwith meat and veggies",     "price": 350, "image": "res://assets/FOOD ASSETS/shop/pansit.png"},
	{"id": "menudo",    "name": "Menudo",           "desc": "Pork and liver stew\nwith tomato sauce",        "price": 450, "image": "res://assets/FOOD ASSETS/shop/menudo.png"},
	{"id": "bbq",       "name": "BBQ Chicken",      "desc": "Tender chicken\nsmothered in BBQ sauce",        "price": 550, "image": "res://assets/FOOD ASSETS/shop/barbeque_chicken.png"},
	{"id": "pastil",    "name": "Chicken Pastil",   "desc": "Shredded chicken\nwrapped in banana leaf",      "price": 700, "image": "res://assets/FOOD ASSETS/shop/chicken_pastil.png"},
	{"id": "finger",    "name": "Chicken Fingers",  "desc": "Crispy breaded strips\nserved with dip",        "price": 900, "image": "res://assets/FOOD ASSETS/shop/chicken_fingers.png"},
	{"id": "carbonara", "name": "Carbonara",        "desc": "Creamy pasta topped\nwith bacon and cheese",    "price": 1000, "image": "res://assets/FOOD ASSETS/shop/carbonara.png"},
]

var table_upgrades := [
	{"id": "table_1", "name": "Table 1", "desc": "Basic wooden table\nfor small groups",    "price": 350,  "image": "res://assets/FOOD ASSETS/shop/table/table.png"},
	{"id": "table_2", "name": "Table 2", "desc": "Sturdy family table\nseats up to six",    "price": 700, "image": "res://assets/FOOD ASSETS/shop/table/table.png"},
	{"id": "table_3", "name": "Table 3", "desc": "Large banquet table\nfor big gatherings", "price": 1400, "image": "res://assets/FOOD ASSETS/shop/table/table.png"},
]

# ── Node refs ─────────────────────────────────────────────────────────────────
@onready var card_container : HBoxContainer = %CardContainer
@onready var tab_ulam  : Button = %TabUlam
@onready var tab_table : Button = $%TabTable

# Preload the card scene (TSCN, not scripted)
const CARD_SCENE := preload("res://scenes/shop_scene/upgrade_card.tscn")

var _font : FontFile = null

func open_shop():
	show()
	get_tree().paused = true
	# FREEZE THE GAME! (Stops the clock, stops customers from getting angry)
	print("Shop: Opened the tablet. Game is paused.")
	
func _on_close_button_pressed():
	hide()
	# UNFREEZE THE GAME!
	get_tree().paused = false 
	shop_closed.emit()
	print("Shop: Closed the tablet. Game resumed.")

func _ready() -> void:
	hide()
	_font = load("res://assets/FONT/04B_30__.TTF")
	for btn in [tab_ulam, tab_table]:
		if _font:
			btn.add_theme_font_override("font", _font)
	_populate_cards()

# ── Tab handlers ──────────────────────────────────────────────────────────────
func _on_tab_ulam_pressed() -> void:
	current_tab   = "ulam"
	selected_card = -1
	_populate_cards()

func _on_tab_table_pressed() -> void:
	current_tab   = "table"
	selected_card = -1
	_populate_cards()

# ── Populate cards from TSCN ──────────────────────────────────────────────────
func _populate_cards() -> void:
	for child in card_container.get_children():
		child.queue_free()
	card_container.alignment = BoxContainer.ALIGNMENT_CENTER
	card_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var data := ulam_upgrades if current_tab == "ulam" else table_upgrades
	for i in data.size():
		_setup_card(CARD_SCENE.instantiate(), data[i], i)

func _setup_card(card: PanelContainer, item: Dictionary, index: int) -> void:
	# ── Fill in data ──────────────────────────────────────────────────────────
	card.get_node("Margin/VBox/NameLabel").text = item["name"]
	card.get_node("Margin/VBox/DescLabel").text = item["desc"]
	
	# Apply font to labels and buy button
	if _font:
		for path in ["Margin/VBox/NameLabel", "Margin/VBox/DescLabel",
				"Margin/VBox/BuyButton/PillWrap/WhitePill/BtnRow/PriceLabel"]:
			card.get_node(path).add_theme_font_override("font", _font)
		card.get_node("Margin/VBox/BuyButton").add_theme_font_override("font", _font)

	# ── Image vs placeholder ──────────────────────────────────────────────────
	var placeholder : Panel      = card.get_node("Margin/VBox/ImageWrap/Placeholder")
	var item_image  : TextureRect = card.get_node("Margin/VBox/ImageWrap/ItemImage")
	if item.has("image"):
		var tex = load(item["image"])
		if tex:
			item_image.texture  = tex
			item_image.visible  = true
			placeholder.visible = false
	else:
		item_image.visible  = false
		placeholder.visible = true

	# ── Buy button Logic ─────────
	var buy_btn : Button = card.get_node("Margin/VBox/BuyButton")
	var price_label : Label = card.get_node("Margin/VBox/BuyButton/PillWrap/WhitePill/BtnRow/PriceLabel")
	
	# Check if this specific item is already owned
	var is_owned = false
	if current_tab == "ulam" and CustomerManager.available_menu["ulam"].has(item["id"]):
		is_owned = true
	elif current_tab == "table":
		# Parses "table_1" into integer 1, "table_2" into 2, etc.
		var table_level = item["id"].trim_prefix("table_").to_int()
		# Check against global unlocked count
		if GameManager.unlocked_tables_count >= table_level:
			is_owned = true
	
	if is_owned:
		buy_btn.disabled = true
		price_label.text = "SOLD" 
	else:
		buy_btn.disabled = false
		price_label.text = str(item["price"])
		# Pass the dictionary and nodes to the function so we can modify them
		buy_btn.pressed.connect(_on_buy_pressed.bind(item, buy_btn, price_label))

	# ── Card-level hover / press effects (script-only, no TSCN involvement) ───
	var card_style : StyleBoxFlat = card.get_theme_stylebox("panel").duplicate()
	card.add_theme_stylebox_override("panel", card_style)

	card.gui_input.connect(_on_card_input.bind(card, card_style, index))
	card.mouse_entered.connect(_on_card_entered.bind(card, card_style))
	card.mouse_exited.connect(_on_card_exited.bind(card, card_style))

	card_container.add_child(card)

# ── Card hover / press effect callbacks ───────────────────────────────────────
func _on_card_input(event: InputEvent, card: PanelContainer, style: StyleBoxFlat, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			style.bg_color = COLOR_CARD_PRESSED
			selected_card  = index
			var tw := create_tween()
			tw.tween_property(card, "scale", Vector2(0.97, 0.97), 0.06).set_ease(Tween.EASE_OUT)
		else:
			style.bg_color = COLOR_CARD_HOVER
			var tw := create_tween()
			tw.tween_property(card, "scale", Vector2(1.04, 1.04), 0.08).set_ease(Tween.EASE_OUT)

func _on_card_entered(card: PanelContainer, style: StyleBoxFlat) -> void:
	style.bg_color = COLOR_CARD_HOVER
	var tw := create_tween()
	tw.tween_property(card, "scale", Vector2(1.04, 1.04), 0.10).set_ease(Tween.EASE_OUT)

func _on_card_exited(card: PanelContainer, style: StyleBoxFlat) -> void:
	style.bg_color = COLOR_CARD_BG
	var tw := create_tween()
	tw.tween_property(card, "scale", Vector2(1.00, 1.00), 0.10).set_ease(Tween.EASE_OUT)

func _on_buy_pressed(item: Dictionary, btn: Button, price_label: Label) -> void:
	print("DEBUG: Shop asks the Bank. Item costs: ", item["price"], " | Bank says total_money is: ", FinanceManager.total_money)
	# 1. Ask the Bank to pay for it
	if FinanceManager.total_money >= item["price"]:
		
		# 2. Add it to the correct Manager
		if current_tab == "ulam":
			CustomerManager.add_new_ulam(item["id"])
		elif current_tab == "table":
			GameManager.unlocked_tables_count += 1
			GameManager.new_table_purchased.emit(GameManager.unlocked_tables_count)
		
		FinanceManager.deduct_funds(item["price"])
		# 3. Save the game immediately so they don't lose the purchase
		SaveManager.save_game()
		
		# 4. Visually update the button so they can't click it again
		btn.disabled = true
		price_label.text = "SOLD"
		
		print("Shop: Successfully bought %s!" % item["name"])
	else:
		print("Shop: Not enough money for %s!" % item["name"])
