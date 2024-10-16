class_name SpellDisplay
extends Button

@export var font_disabled_color: Color
@export var font_selected_color: Color
@export var disabled_box: StyleBox
@export var selected_box: StyleBox

var icon_texture_rect: TextureRect
var name_label: Label

var spell: SpellData

#  The index of this spell in SaveManager.save.spells.
var id: int

func setup(id: int, spell: SpellData):
	self.id = id
	self.spell = spell
	icon_texture_rect = $IconTextureRect
	name_label = $NameLabel
	icon_texture_rect.texture = spell.icon
	name_label.text = spell.display_name

func set_spell_disabled(disabled: bool, selected: bool):
	self.disabled = disabled
	
	if selected:
		add_theme_stylebox_override("disabled", selected_box)
		name_label.add_theme_color_override("font_color", font_selected_color)
	elif disabled:
		add_theme_stylebox_override("disabled", disabled_box)
		name_label.add_theme_color_override("font_color", font_disabled_color)
	else:
		add_theme_stylebox_override("disabled", disabled_box)
		name_label.remove_theme_color_override("font_color")
