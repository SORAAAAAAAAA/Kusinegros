extends TextureButton
class_name TableControl

# 1. State definitions for the table lifecycle
enum State { EMPTY, OCCUPIED, DIRTY }
var current_state: State = State.EMPTY

# Signal to notify the TableManager when cleaning is finished
signal table_cleaned(table: TableControl)

# 2. Export slots to hold your Clean and Dirty PNG assets
@export var clean_texture: Texture2D
@export var dirty_texture: Texture2D

# How long the player must wait while cleaning (in seconds)
@export var cleaning_duration: float = 2.0 
@export var max_customers_before_dirty: int = 3 # --- NEW: Easy to tweak later! ---

@onready var seats_container: Node2D = $Seats
@onready var clean_progress: ProgressBar = $CleanProgress
@onready var clean_timer: Timer = $CleanTimer

var available_seats: Array[Marker2D] = []
var is_cleaning: bool = false
var customers_fed: int = 0 # --- NEW: The 3-Strike Counter! ---

func _ready() -> void:
	reset_seats()
	update_visuals()
	
	# Connect our interactions and countdown timers programmatically
	pressed.connect(_on_table_pressed)
	clean_timer.timeout.connect(_on_cleaning_finished)
	
	# Start the table clean!
	set_state(State.EMPTY)

func _process(_delta: float) -> void:
	# If the player is actively wiping the table, update the progress bar smoothly
	if is_cleaning and not clean_timer.is_stopped():
		var time_passed = cleaning_duration - clean_timer.time_left
		clean_progress.value = (time_passed / cleaning_duration) * 100

# Refills our tracking array with our 3 stool markers
func reset_seats() -> void:
	available_seats.clear()
	for child in seats_container.get_children():
		if child is Marker2D:
			available_seats.append(child)

# Called by arriving student nodes to claim a stool coordinate
func claim_a_seat() -> Marker2D:
	if available_seats.size() > 0:
		var assigned_seat = available_seats.pop_front()
		if current_state == State.EMPTY:
			set_state(State.OCCUPIED)
		return assigned_seat
	return null

# --- NEW: The function the customer calls when they leave ---
func report_customer_finished() -> void:
	customers_fed += 1
	print("Table: Customer left. Customers fed so far: ", customers_fed)
	
	if customers_fed >= max_customers_before_dirty:
		print("Table: 3 customers have eaten! The table is now dirty.")
		set_state(State.DIRTY)

# Changes internal states safely and triggers visuals
func set_state(new_state: State) -> void:
	current_state = new_state
	update_visuals()

# Swaps textures and cursor shapes automatically based on state
func update_visuals() -> void:
	match current_state:
		State.EMPTY, State.OCCUPIED:
			if clean_texture: 
				texture_normal = clean_texture
			mouse_default_cursor_shape = Control.CURSOR_ARROW
			clean_progress.visible = false
			
		State.DIRTY:
			if dirty_texture: 
				texture_normal = dirty_texture
			# Changes mouse to a pointing hand when hovering over a dirty table
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			clean_progress.visible = is_cleaning

# Runs instantly when the player clicks the TextureButton bounding box
func _on_table_pressed() -> void:
	print("PHYSICAL CLICK REGISTERED!")
	if current_state == State.DIRTY and not is_cleaning:
		start_cleaning()

func start_cleaning() -> void:
	is_cleaning = true
	clean_progress.value = 0
	clean_progress.visible = true
	clean_timer.start(cleaning_duration)
	print("Wiping down the table...")

func _on_cleaning_finished() -> void:
	is_cleaning = false
	customers_fed = 0 # --- NEW: Reset the loop! ---
	set_state(State.EMPTY)
	reset_seats() # Re-open all 3 stools for the next batch of students
	table_cleaned.emit(self)
	print("Table is sparkling clean and ready for 3 more customers!")
