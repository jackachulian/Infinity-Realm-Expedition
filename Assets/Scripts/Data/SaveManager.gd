class_name SaveManager
extends Node

@export var load_on_ready: bool = true

# The currently loaded save.
static var save: SaveFile

const SAVE_FILE_NAME = "user://savegame.tres"

func _init() -> void:
	if load_on_ready:
		if saved_game_exists():
			load_game()
		else:
			new_game()
			
func _ready():
	if save:
		setup_game()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit() # default behavior

func new_game():
	print("created new game")
	save = SaveFile.new()
	
func saved_game_exists() -> bool:
	return ResourceLoader.exists(SAVE_FILE_NAME)
	
func load_game():
	if saved_game_exists():
		var loaded_save = ResourceLoader.load(SAVE_FILE_NAME)
		if loaded_save is SaveFile: # Check that the data is valid
			print("loaded save file at ", SAVE_FILE_NAME)
			save = loaded_save
		else:
			printerr("Failed to load save file")
	
# Call appropriate functions to load equipped spells, weapons, etc. after the save file is successfully loaded.
# Called on ready
func setup_player_entity():
	if not Entity.player:
		printerr("Trying to setup player before player entity is instantiated!")
		return
	
	if save.equipped_weapon >= len(save.weapons):
		printerr("Corrupt save: Invalid equipped weapon. Fixing by unequipping weapon.")
		save.equipped_weapon = -1
			
	if save.equipped_weapon > 0:
		var weapon_name = save.weapons[save.equipped_weapon]
		var weapon_data = SpellData.load_spell_data(weapon_name)
		var equipped_weapon = weapon_data.instantiate_equipped_spell()
		

# Note: This can be called from anywhere inside the tree. This function is
# path independent.
# Go through everything in the persist category and ask them to return a
# dict of relevant variables.
func save_game():
	var result = ResourceSaver.save(save, SAVE_FILE_NAME)
	if result == OK:
		print("Saved file at ", SAVE_FILE_NAME)
	else:
		printerr("Could not save file: ", result)
	
