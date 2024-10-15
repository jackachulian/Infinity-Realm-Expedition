class_name EquippedSpellSubmenu
extends PanelContainer

@onready var spell_container: HBoxContainer = $VBoxContainer/SpellContainer

@onready var spell_display_item_scene: PackedScene = preload("res://Assets/Scenes/Menus/spell_icon_display.tscn")

signal spell_pressed(spell_icon_display: SpellIconDisplay)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in spell_container.get_children():
		child.queue_free()

func display_equipped_spells():
	for child in spell_container.get_children():
		child.queue_free()

	for i in range(len(Entity.player.spells)):
		var spell: EquippedSpell = Entity.player.spells[i]
		var spell_display: SpellIconDisplay = spell_display_item_scene.instantiate()
		spell_container.add_child(spell_display)
		spell_display.setup_equipped(spell, i+1)
		spell_display.pressed.connect(func(): _on_spell_pressed(spell_display))
		
func _on_spell_pressed(spell_icon_display: SpellIconDisplay):
	spell_pressed.emit(spell_icon_display)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
