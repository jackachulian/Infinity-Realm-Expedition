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
	setup_player_entity()
		

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
	if not save:
		printerr("Trying to set up player but no save is loaded!")
		return
		
	if not Entity.player:
		printerr("Trying to setup player before player entity is instantiated!")
		return
	
	if save.equipped_weapon >= len(save.weapons):
		printerr("Corrupt save: Invalid equipped weapon. Fixing by unequipping weapon.")
		save.equipped_weapon = -1
			
	if save.equipped_weapon >= 0:
		var weapon_name = save.weapons[save.equipped_weapon]
		var weapon_data := WeaponData.load_weapon_data(weapon_name)
		if weapon_data:
			Entity.player.equip_weapon(weapon_data)
		
	for i in len(save.equipped_spells):
		var id = save.equipped_spells[i]
		if id >= 0:
			var spell_name = save.spells[id]
			var spell_data = SpellData.load_spell_data(spell_name)
			Entity.player.equip(i+1, spell_data)
			
	BattleHud.instance.setup_spells()

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
	
