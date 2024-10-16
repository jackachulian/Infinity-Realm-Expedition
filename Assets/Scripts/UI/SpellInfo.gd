class_name SpellInfo
extends Control

@onready var spell_icon: TextureRect = $PanelContainer/SpellIcon
@onready var name_label: Label = $NameLabel
@onready var element_icon: TextureRect = $NameLabel/TextureRect
@onready var damage_label: Label = $TopRows/Damage/Label
@onready var mana_label: Label = $TopRows/ManaCost/Label
@onready var cooldown_label: Label = $TopRows/SpeedOrCooldown/Label
@onready var knockback_label: Label = $TopRows/Knockback/Label
@onready var description_label: Label = $Description


func display(spell: SpellData):
	spell_icon.texture = spell.icon
	name_label.text = spell.display_name
	element_icon.texture = Elements.element_icons[spell.primary_element]
	damage_label.text = "%s damage" % spell.damage
	mana_label.text = "Uses %s mana" % spell.mana_cost
	cooldown_label.text = "%s: %ss" % ["Cooldown" if spell.is_burst else "Cast delay", spell.cast_delay]
	knockback_label.text = "Knockback: %s" % spell.knockback
	description_label.text = spell.description
