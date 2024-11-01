# A HUD for viewing the state of the current player's entity.
# No actual player or entity logic should be stored here, 
# as players should be able to exist in the world without a HUD, 
# per my flimsy game design principles.
class_name BattleHud
extends Control

static var instance: BattleHud

@onready var spell_container: HBoxContainer = $SpellContainer
@onready var weapon_display: SpellIconDisplay = $WeaponSpellDisplayItem
@onready var enemy_guis: CanvasLayer = $EnemyGUIs
@onready var health_bar: ProgressBar = $HealthBar
@onready var spell_display_item_scene: PackedScene = preload("res://Assets/Scenes/Menus/spell_icon_display.tscn")


func _enter_tree() -> void:
	instance = self

func _ready():
	instance = self
	if Entity.player:
		setup_spells()
		health_bar.max_value = Entity.player.max_hit_points
		Entity.player.damaged.connect(on_entity_damaged)

func setup_spells():
	for child in spell_container.get_children():
		child.queue_free()
	
	if Entity.player.weapon:
		weapon_display.setup_equipped(Entity.player.weapon, 0, true)
	else:
		weapon_display.setup_equipped(null, 0, true)
		
	for i in range(len(Entity.player.spells)):
		var spell: EquippedSpell = Entity.player.spells[i]
		var spell_display: SpellIconDisplay = spell_display_item_scene.instantiate()
		spell_container.add_child(spell_display)
		spell_display.setup_equipped(spell, i+1, true)

func select_spell(spell_number: int):
	var disp: SpellIconDisplay = spell_container.get_child(spell_number - 1)
	if disp:
		disp.grab_focus()

func on_entity_damaged(damage: int):
	health_bar.value = Entity.player.hit_points
