class_name SpellDisplay
extends Button

var icon_texture_rect: TextureRect
var name_label: Label

func setup(spell: SpellData):
	icon_texture_rect = $IconTextureRect
	name_label = $NameLabel
	icon_texture_rect.texture = spell.icon
	name_label.text = spell.display_name

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
