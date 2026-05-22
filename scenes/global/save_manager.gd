extends Node

const SAVE_PATH = "user://kusinegros_save.json"

func save_game():
	# 1. Gather the data from your Managers
	var data_to_save = {
		"day": TimeManager.current_day,
		"money": FinanceManager.total_money
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
		print("Archivist: Game loaded! Welcome back to Day ", TimeManager.current_day)
		return true
		
	print("Archivist: ERROR - Failed to parse save data!")
	return false

# A quick helper function for your Main Menu to check if the button should be clickable
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
