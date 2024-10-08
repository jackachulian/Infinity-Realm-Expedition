class_name Spell
extends Node3D

# Element shown in the spells menu for this spell
@export var primary_type: Elements.Element

# Must have this much mana to use the spell.
@export var mana_cost: int

# Cooldown before this spell can be cast again after using
@export var cast_delay: float

# State to enter when using this spell (Should be a child of this spell node)
@export var entry_state: State

# Type shown in the spell details menu
# Based on the power types explained on the lemnsicate wiki
# https://lemniscate.fandom.com/wiki/Power_System#Magic_Types
enum SpellType {
	PROJECTILE,
	DEVICE, # weapon
	HELPER,
	MODIFIER
}
