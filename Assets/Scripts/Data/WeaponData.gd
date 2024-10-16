class_name WeaponData
extends SpellData

# Constant rate of mana drained per second while this weapon is activated.
@export var mana_drain: float = 0.0

# Mana cost to summon this weapon.
@export var summon_cost: float = 0.0

# Durability of the weapon. While active, player can take at most this much damage before the weapon breaks.
# If 0, weapon is unbreakable.
@export var durability: int = 0

static func load_weapon_data(name: String) -> WeaponData:
	return load("res://Assets/Database/Weapons/"+name+".tres")
