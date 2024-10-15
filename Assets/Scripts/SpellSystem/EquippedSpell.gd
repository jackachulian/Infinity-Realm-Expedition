class_name EquippedSpell
extends Node3D

# NOTE: The name of this node, is used to get the SpellData that defines the stats
# ex.
# fireball will get SpellData from Assets/Database/Spells/fireball.tres 
# iron_sword will get SpellData from Assets/Database/Weapons/iron_sword.tres

# State to enter when using this spell (Should be a child of this spell node)
@export var entry_state: State

var data: SpellData

# The entity that currently has this spell equipped, if any.
var entity: Entity

var cast_cooldown_remaining: float

func _process(delta: float) -> void:
	if cast_cooldown_remaining > 0:
		cast_cooldown_remaining = move_toward(cast_cooldown_remaining, 0, delta)

# Returns true only if the passed entity can use the spell.
func can_be_used(entity: Entity) -> bool:
	# If this is a projectile-type spell and shoot maker is obstructed, can't use this spell
	if data.spell_type == SpellData.SpellType.PROJECTILE and entity.is_shoot_obstructed():
		return false
	
	# TODO: check for mana cost
	return cast_cooldown_remaining <= 0

# subtracts mana and sets cooldown. called from withing GenericInput.gd in request_action()
func consume_use() -> void:
	# TODO: subtract mana cost
	cast_cooldown_remaining = data.cast_delay

func equip(entity: Entity):
	if not data:
		data = SpellData.load_spell_data(name)
		
	print("equipping weapon/spell ", name)
	self.entity = entity
	entity.state_machine.setup_states(self)
	visible = true
	
