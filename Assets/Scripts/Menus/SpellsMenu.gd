class_name SpellsMenu
extends Control

var opened: bool = false
signal exited

@export var spell_display_scene: PackedScene

@onready var spell_container: VBoxContainer = $SpellContainer


func _input(event: InputEvent) -> void:
	if opened and event.is_action_pressed("ui_cancel"):
		exit()
		get_viewport().set_input_as_handled()

func open():
	opened = true
	visible = true
	
	display_spells()
	
	var fc = spell_container.get_child(0) as Control
	if fc:
		fc.grab_focus()
	
func exit():
	opened = false
	visible = false
	exited.emit(self)

func display_spells():
	for child in spell_container.get_children():
		child.queue_free()
		
	if not spell_display_scene:
		printerr("spell display scene no exist on spell menu")
		return
	
	for spell_name in SaveManager.save.spells:
		var spell_data: SpellData = load("res://Assets/Database/Spells/"+spell_name+".tres")
		var spell_display: SpellDisplay = spell_display_scene.instantiate() as SpellDisplay
		spell_container.add_child(spell_display)
		spell_display.setup(spell_data)

func _on_exit_pressed():
	exit()
