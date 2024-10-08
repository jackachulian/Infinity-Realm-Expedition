class_name Weapon
extends Spell

@export var weapon_model: Node3D

func equip(entity: Entity):
	print("equipping weapon ", name)
	
	entity.state_machine.setup_states(self)
	
	if weapon_model:
		remove_child(weapon_model)
		entity.weapon_parent_node.add_child(weapon_model)
		weapon_model.visible = true
