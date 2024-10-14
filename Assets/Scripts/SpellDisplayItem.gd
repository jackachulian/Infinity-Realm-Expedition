class_name SpellDisplayItem
extends Control

@onready var icon_texture_rect: TextureRect = $IconTextureRect
@onready var spell_number_label: Label = $SpellNumberLabel



# Called when the node enters the scene tree for the first time.
func setup(spell: Spell, spell_number: int):
	if spell.spell_icon:
		icon_texture_rect.texture = spell.spell_icon
		
	if spell_number > 0:
		spell_number_label.text = str(spell_number)
	else:
		spell_number_label.text = ""
