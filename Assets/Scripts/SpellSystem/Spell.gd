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


var cast_cooldown_remaining: float

# Type shown in the spell details menu
# Based on the power types explained on the lemnsicate wiki
# https://lemniscate.fandom.com/wiki/Power_System#Magic_Types
enum SpellType {
	PROJECTILE,
	DEVICE, # weapon
	HELPER,
	MODIFIER
}

func _process(delta: float) -> void:
	if cast_cooldown_remaining > 0:
		cast_cooldown_remaining = move_toward(cast_cooldown_remaining, 0, delta)

func can_be_used() -> bool:
	# TODO: check for mana cost
	return cast_cooldown_remaining <= 0
	
# subtracts mana and sets cooldown. called from withing GenericInput.gd in request_action()
func consume_use() -> void:
	# TODO: subtract mana cost
	cast_cooldown_remaining = cast_delay

func equip(entity: Entity):
	print("equipping weapon/spell ", name)
	entity.state_machine.setup_states(self)
	visible = true
