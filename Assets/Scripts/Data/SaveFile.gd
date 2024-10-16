class_name SaveFile
extends Resource

# List of spells in inventory. 
# Strings in this array are the name of the reosurces in Assets/Database/Spells.
@export var spells: PackedStringArray

# List of weapons in inventory
@export var weapons: PackedStringArray
	
# Contains which spells are currently equipped by the player.
# Index is the spell slot, value is the index in the spells array.
# The length of this array dictates how many spells the player can equip.
# -1 for no spell equipped in this slot.
@export var equipped_spells: Array[int]

# The weapon equipped. Value is the index in the weapons array. -1 for no weapon equipped.
@export var equipped_weapon: int = -1

func _init() -> void:
	spells.append("fireball")
	spells.append("fireball")
	spells.append("fireball")
	spells.append("waterball")
	weapons.append("ironsword")
	
	equipped_spells.resize(3)
