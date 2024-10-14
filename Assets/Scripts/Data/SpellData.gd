class_name SpellData
extends Resource

# Displayed name of the spell
@export var display_name: String

# Texture displayed on the battle HUD for this spell
@export var icon: Texture2D

# Element shown in the spells menu for this spell
@export var primary_type: Elements.Element

# Must have this much mana to use the spell.
@export var mana_cost: int

# Cooldown before this spell can be cast again after using
@export var cast_delay: float

# Contains a scene. Root node is a Spell
@export var equip_node: PackedScene

# Type shown in the spell details menu
# Based on the power types explained on the lemnsicate wiki
# https://lemniscate.fandom.com/wiki/Power_System#Magic_Types
enum SpellType {
	PROJECTILE,
	DEVICE, # weapon
	HELPER,
	MODIFIER
}
@export var spell_type: SpellType
