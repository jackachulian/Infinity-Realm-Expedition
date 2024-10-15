class_name SpellDisplay
extends Button

@onready var icon_texture_rect: TextureRect = $IconTextureRect
@onready var name_label: Label = $NameLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func setup(spell: SpellData):
	icon_texture_rect.texture = spell.icon
	name_label.text = spell.display_name

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
