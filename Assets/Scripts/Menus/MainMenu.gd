extends Control

@export var new_game_scene: PackedScene

func _on_play_pressed():
	get_tree().change_scene_to_packed(new_game_scene)
	
func _on_options_pressed():
	pass
	
func _on_quit_pressed():
	get_tree().quit()
