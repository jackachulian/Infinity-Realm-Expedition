class_name OptionsMenu
extends Control

var opened: bool = false

signal exited

func _input(event: InputEvent) -> void:
	if opened and event.is_action_pressed("ui_cancel"):
		exit()
		get_viewport().set_input_as_handled()

func open():
	print("opening options menu")
	opened = true
	visible = true
	
func exit():
	print("closing options menu")
	opened = false
	visible = false
	exited.emit(self)

func _on_exit_pressed():
	exit()
