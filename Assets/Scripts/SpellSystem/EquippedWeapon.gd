class_name EquippedWeapon
extends EquippedSpell


# Node that is parented to the user's hand (or whatever bone parent holds their weapon) when activated
@export var weapon_model: Node3D

# If false, this is a physical non-summoned weapon and it will be "summoned" (placed into hand) as soon as and while it is equipped.
@export var is_summoned: bool = true

# data should ideally be of tpye WeaponData
var weapon_data: WeaponData:
	get():
		return data as WeaponData

func load_data_from_database():
	data = load("res://Assets/Database/Weapons/"+name+".tres")

func equip(entity: Entity):
	super.equip(entity)
	if not is_summoned:
		summon()

func summon():
	# Parent weapon model to the entity's hand
	if weapon_model:
		var scale = weapon_model.scale
		remove_child(weapon_model)
		entity.weapon_model_parent.add_child(weapon_model)
		weapon_model.visible = true
		weapon_model.scale = scale
