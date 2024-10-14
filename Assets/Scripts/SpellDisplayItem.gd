class_name SpellDisplayItem
extends Control

@onready var icon_texture_rect: TextureRect = $IconTextureRect
@onready var spell_number_label: Label = $SpellNumberLabel



# Called when the node enters the scene tree for the first time.
func setup(equipped_spell: EquippedSpell, spell_number: int):
	if equipped_spell.data.icon:
		icon_texture_rect.texture = equipped_spell.data.icon
		
	if spell_number > 0:
		spell_number_label.text = str(spell_number)
	else:
		spell_number_label.text = ""
