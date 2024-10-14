# Note: This can be called from anywhere inside the tree. This function is
# path independent.
# Go through everything in the persist category and ask them to return a
# dict of relevant variables.
func save_game():
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	
	var data = {
		
	}

	# Store the save dictionary as a new line in the save file.
	save_file.store_string(JSON.stringify(data))
