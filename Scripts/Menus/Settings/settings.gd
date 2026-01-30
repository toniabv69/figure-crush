extends Node2D

func _on_logout_button_button_up() -> void:
	BackendConnectionManager.logout()
	BackendConnectionManager.save_credentials("", {})
	get_tree().change_scene_to_file("res://Scenes/Menus/LoadingScreen/loading_screen.tscn")

func _on_delete_account_button_button_up() -> void:
	for child in get_children():
		if child is Panel:
			child.show()
		else:
			child.hide()

func _on_back_button_button_up() -> void:
	get_node("..").hide_settings_menu()

func _on_confirm_button_button_up() -> void:
	var result = await BackendConnectionManager.delete_account($DeletePanel/PasswordTextbox.text)
	if result:
		BackendConnectionManager.logout()
		get_tree().change_scene_to_file("res://Scenes/Menus/LoadingScreen/loading_screen.tscn")
	else:
		$DeletePanel/SureLabel.text = "Invalid Password!"

func _on_delete_back_button_button_up() -> void:
	for child in get_children():
		if child is Panel:
			child.hide()
		else:
			child.show()
