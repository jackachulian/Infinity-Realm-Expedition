# Shows the spell's icon inside a box witha  number indicating the key to use.
# Used to display equipped spells accross the project, mainly the battle HUD and the spell equip screen.
class_name SpellIconDisplay
extends Button

@onready var icon_texture_rect: TextureRect = $IconTextureRect
@onready var spell_number_label: Label = $SpellNumberLabel

var equipped_spell: EquippedSpell # will be null if this isn't equipped and just in the inventory
var spell_data: SpellData
var spell_number: int 

func setup_equipped(equipped_spell: EquippedSpell, spell_number: int, in_battle: bool = false):
	self.equipped_spell = equipped_spell
	
	if in_battle:
		focus_mode = FocusMode.FOCUS_CLICK
	else:
		focus_mode = FocusMode.FOCUS_ALL
	
	if equipped_spell:
		setup_data(equipped_spell.data, spell_number)
	else:
		setup_data(null, spell_number)

func setup_data(spell_data: SpellData, spell_number: int):
	self.spell_data = spell_data
	self.spell_number = spell_number
	
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
