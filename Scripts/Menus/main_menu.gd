extends Node2D

func _on_matchmake_button_button_up() -> void:
	MatchmakingConnectionManager.start_matchmaking()

func _on_play_level_debug_button_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/Level/level.tscn")
	
func _on_settings_button_button_up() -> void:
	for child in get_children():
		if child is not Button:
			child.show()
		else:
			child.hide()
			
func hide_settings_menu():
	for child in get_children():
		if child is not Button:
			child.hide()
		else:
			child.show()
