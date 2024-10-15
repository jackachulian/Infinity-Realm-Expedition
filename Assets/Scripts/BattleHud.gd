# A HUD for viewing the state of the current player's entity.
# No actual player or entity logic should be stored here, 
# as players should be able to exist in the world without a HUD, 
# per my flimsy game design principles.
class_name BattleHud
extends Control

static var instance: BattleHud

@onready var spell_container: HBoxContainer = $SpellContainer

@onready var weapon_display: SpellIconDisplay = $WeaponSpellDisplayItem

@onready var spell_display_item_scene: PackedScene = preload("res://Assets/Scenes/Menus/spell_icon_display.tscn")

func _enter_tree() -> void:
	instance = self

func _ready():
	if Entity.player:
		setup()

func setup():
	for child in spell_container.get_children():
		child.queue_free()
	
	if Entity.player.weapon:
		weapon_display.setup(Entity.player.weapon, 0)
	else:
		weapon_display.setup(null, 0)
		
	for i in range(len(Entity.player.spells)):
		var spell: EquippedSpell = Entity.player.spells[i]
		var spell_display: SpellIconDisplay = spell_display_item_scene.instantiate()
		spell_container.add_child(spell_display)
		spell_display.setup_equipped(spell, i+1)
