class_name PauseMenu
extends Control

@onready var pause_menu_buttons: Control = $PauseMenuButtons
@onready var options_menu: OptionsMenu = $OptionsMenu
@onready var spells_button: Button = $PauseMenuButtons/SpellsButton


var last_focused_control: Control
var paused: bool = false

func _ready() -> void:
	pause_menu_buttons.visible = true
	options_menu.visible = false
	options_menu.exited.connect(_on_options_exited)
	visible = false
	last_focused_control = spells_button
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if not get_tree().paused:
			pause()
		elif pause_menu_buttons.visible:
			unpause()
			
	elif pause_menu_buttons.visible and event.is_action_pressed("ui_cancel"):
		unpause()	
	
func pause():
	get_tree().paused = true
	visible = true
	open()
	
func unpause():
	exit()
	visible = false
	get_tree().paused = false
	
func open():
	pause_menu_buttons.visible = true
	last_focused_control.grab_focus()
	
func exit():
	last_focused_control = get_viewport().gui_get_focus_owner()
	pause_menu_buttons.visible = false

func _on_spells_pressed():
	pass
	
func _on_equipment_pressed():
	pass
	
func _on_items_pressed():
	pass
	
func _on_records_pressed():
	pass
	
func _on_options_pressed():
	exit()
	options_menu.open()
	
func _on_options_exited():
	open()
