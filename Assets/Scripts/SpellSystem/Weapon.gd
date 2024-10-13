class_name Weapon
extends Spell

# Node that is parented to the user's hand (or whatever bone parent holds their weapon) when activated
@export var weapon_model: Node3D

# Constant rate of mana drained per second while this weapon is activated.
@export var mana_drain: float = 0.0

# Mana cost to summon this weapon.
@export var summon_cost: float = 0.0

# Durability of the weapon. While active, player can take at most this much damage before the weapon breaks.
# If 0, weapon is unbreakable.
@export var durability: int = 0

# If false, this is a physical non-summoned weapon and it will be "summoned" (placed into hand) as soon as and while it is equipped.
@export var is_summoned: bool = true

func equip(entity: Entity):
	super.equip(entity)
	if not is_summoned:
		summon()

func summon():
	# Parent weapon model to the entity's hand
	if weapon_model:
		var scale = weapon_model.scale
		remove_child(weapon_model)
		entity.weapon_parent_node.add_child(weapon_model)
		weapon_model.visible = true
		weapon_model.scale = scale
