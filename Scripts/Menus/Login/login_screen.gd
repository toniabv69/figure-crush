extends Node2D

func _on_login_button_button_up() -> void:
	if $Panel/EmailTextbox.text != "" and $Panel/PasswordTextbox.text != "":
		if await BackendConnectionManager.login_player($Panel/EmailTextbox.text, $Panel/PasswordTextbox.text):
			get_node("..").continue_loading()
		else:
			$Panel/InfoLabel.text = "Login failed: invalid credentials."
	else:
		$Panel/InfoLabel.text = "Login failed: empty fields."


func _on_no_account_button_button_up() -> void:
	get_node("..").show_register_screen()
