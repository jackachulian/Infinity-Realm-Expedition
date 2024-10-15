class_name SpellsMenu
extends Control

var opened: bool = false
signal exited

@onready var v_box_container: VBoxContainer = $VBoxContainer


func _input(event: InputEvent) -> void:
	if opened and event.is_action_pressed("ui_cancel"):
		exit()
		get_viewport().set_input_as_handled()

func open():
	opened = true
	visible = true
	var fc = v_box_container.get_child(0) as Control
	if fc:
		fc.grab_focus()
	
func exit():
	opened = false
	visible = false
	exited.emit(self)

func _on_exit_pressed():
	exit()
