class_name SpellDisplay
extends Button

var icon_texture_rect: TextureRect
var name_label: Label

var spell: SpellData

func _ready() -> void:
	pressed.connect(on_pressed)

func setup(spell: SpellData):
	self.spell = spell
	icon_texture_rect = $IconTextureRect
	name_label = $NameLabel
	icon_texture_rect.texture = spell.icon
	name_label.text = spell.display_name

func on_pressed():
	if not spell:
		return
		
	
