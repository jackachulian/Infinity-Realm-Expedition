class_name Weapon
extends Spell

# Node that is aprented to the user when equipped
@export var weapon_model: Node3D

# Constant rate of mana drained per second while this weapon is equipped.
@export var mana_drain: float = 0.0

func equip(entity: Entity):
	super.equip(entity)
	if weapon_model:
		remove_child(weapon_model)
		entity.weapon_parent_node.add_child(weapon_model)
		weapon_model.visible = true
