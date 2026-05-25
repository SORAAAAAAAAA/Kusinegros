extends Node

const SAVE_PATH = "user://kusinegros_save.json"

func delete_save():
	# First, check if a save file even exists
	if FileAccess.file_exists(SAVE_PATH):
		# If it does, physically delete it from the hard drive
		DirAccess.remove_absolute(SAVE_PATH)
		print("SaveManager: Old save file physically deleted!")
	else:
		print("SaveManager: No save file found to delete. Starting completely fresh!")
	

func save_game():
	# 1. Gather the data from your Managers
	# Notice we removed the TimeManager changes here! We just read the current day.
	var data_to_save = {
		"day": TimeManager.current_day,
		"money": FinanceManager.total_money,
		"available_menu": CustomerManager.available_menu,
		"unlocked_tables": GameManager.unlocked_tables_count
	}
	
	# 2. Open the file and write the JSON data
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	# ✅ CHECK IF FILE IS NULL BEFORE USING IT!
	if file == null:
		var error = FileAccess.get_open_error()
		print("Archivist: ERROR - Failed to open file! Error code: ", error)
		return
	
	file.store_string(JSON.stringify(data_to_save))
	file.close()
	print("Archivist: Game saved! File written to hard drive.")

func load_game() -> bool:
	# 1. Check if a save file actually exists first!
	if not FileAccess.file_exists(SAVE_PATH):
		print("Archivist: No save file found.")
		return false
		
	# 2. Open the file and read the text
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	
	# ✅ CHECK IF FILE IS NULL!
	if file == null:
		var error = FileAccess.get_open_error()
		print("Archivist: ERROR - Failed to open file! Error code: ", error)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var saved_data = JSON.parse_string(json_string)
	
	# 3. Inject the data back into the Managers!
	if saved_data:
		TimeManager.current_day = saved_data["day"]
		FinanceManager.total_money = saved_data["money"]
		CustomerManager.available_menu = saved_data["available_menu"]
		
		if saved_data.has("unlocked_tables"):
			GameManager.unlocked_tables_count = saved_data["unlocked_tables"]
		else:
			GameManager.unlocked_tables_count = 0
		print("Archivist: Game loaded! Welcome back to Day ", TimeManager.current_day)
		return true
		
	print("Archivist: ERROR - Failed to parse save data!")
	return false

# A quick helper function for your Main Menu to check if the button should be clickable
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
	
