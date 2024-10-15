# Shows the spell's icon inside a box witha  number indicating the key to use.
# Used to display equipped spells accross the project, mainly the battle HUD and the spell equip screen.
class_name SpellIconDisplay
extends Control

@onready var icon_texture_rect: TextureRect = $IconTextureRect
@onready var spell_number_label: Label = $SpellNumberLabel

func setup_equipped(equipped_spell: EquippedSpell, spell_number: int):
	setup_data(equipped_spell.data, spell_number)

func setup_data(spell_data: SpellData, spell_number: int):
	if not spell_data:
		icon_texture_rect.texture = null
		spell_number_label.text = ""
		return
	
	if spell_data.icon:
		icon_texture_rect.texture = spell_data.icon
		
	if spell_number > 0:
		spell_number_label.text = str(spell_number)
	else:
		spell_number_label.text = ""
