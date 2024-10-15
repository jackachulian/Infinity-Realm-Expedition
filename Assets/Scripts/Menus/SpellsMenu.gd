class_name SpellsMenu
extends Control

var opened: bool = false
signal exited

@export var spell_display_scene: PackedScene

@onready var spell_container: VBoxContainer = $SpellContainer

@onready var equipped_spells: EquippedSpellSubmenu = $EquippedSpells

# The spell display that was pressed in the menu and is currently being managed (swap, equip, unequip, etc).
# Null for no spell currently being managed.
var selected_spell_display: SpellDisplay

func _ready() -> void:
	equipped_spells.spell_pressed.connect(_on_equipped_spell_pressed)

func _input(event: InputEvent) -> void:
	if opened and event.is_action_pressed("ui_cancel"):
		if selected_spell_display:
			close_equipped_spells()
		else:
			exit()
			get_viewport().set_input_as_handled()

func open():
	opened = true
	visible = true
	equipped_spells.visible = false
	
	display_spells()
	
func exit():
	opened = false
	visible = false
	exited.emit(self)

func open_equipped_spells():
	for disp: SpellDisplay in spell_container.get_children():
		var selected = disp == selected_spell_display
		disp.set_spell_disabled(true, selected)
		disp.focus_mode = FocusMode.FOCUS_NONE
	equipped_spells.visible = true
	equipped_spells.display_equipped_spells()
	await get_tree().process_frame
	var first: SpellIconDisplay = equipped_spells.spell_container.get_child(0)
	if first:
		first.grab_focus()

func close_equipped_spells():
	for disp: SpellDisplay in spell_container.get_children():
		disp.set_spell_disabled(false, false)
		disp.focus_mode = FocusMode.FOCUS_ALL
	equipped_spells.visible = false
	selected_spell_display.grab_focus()
	selected_spell_display = null

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
		spell_display.pressed.connect(func(): _on_spell_display_pressed(spell_display))
		
	await get_tree().process_frame
		
	var first: SpellDisplay = spell_container.get_child(0)
	if first:
		first.grab_focus()

func _on_spell_display_pressed(spell_display: SpellDisplay):
	selected_spell_display = spell_display
	open_equipped_spells()
	

func _on_equipped_spell_pressed(spell_icon_display: SpellIconDisplay):
	var spell_number: int = spell_icon_display.spell_number
	if Entity.player.spells[spell_number-1] != null:
		Entity.player.unequip(spell_number)
	Entity.player.equip(spell_number, selected_spell_display.spell)
	BattleHud.instance.setup_spells()
	close_equipped_spells()

func _on_exit_pressed():
	exit()
