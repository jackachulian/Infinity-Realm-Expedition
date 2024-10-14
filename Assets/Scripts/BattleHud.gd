# A HUD for viewing the state of the current player's entity.
# No actual player or entity logic should be stored here, 
# as players should be able to exist in the world without a HUD, 
# per my flimsy game design principles.
class_name BattleHud
extends Control

# Entity the player controls. Player entity's spells will be displayed in the hud.
@export var player: Entity

@export var spell_display_item_scene: PackedScene


static var instance: BattleHud

@onready var spell_container: HBoxContainer = $SpellContainer

@onready var weapon_display: SpellDisplayItem = $WeaponSpellDisplayItem



func _enter_tree() -> void:
	instance = self

func _ready():
	if player:
		setup()

func setup():
	for child in spell_container.get_children():
		child.queue_free()
		
	weapon_display.setup(player.weapon, 0)
		
	for i in range(len(player.spells)):
		var spell: Spell = player.spells[i]
		var spell_display: SpellDisplayItem = spell_display_item_scene.instantiate()
		spell_container.add_child(spell_display)
		spell_display.setup(spell, i+1)
