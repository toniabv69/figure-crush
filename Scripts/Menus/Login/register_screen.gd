extends Node2D

func _on_register_button_button_up() -> void:
	if $Panel/EmailTextbox.text != "" and $Panel/PasswordTextbox.text != "" and \
	$Panel/ConfirmTextbox.text != "" and $Panel/UsernameTextbox.text != "":
		if $Panel/ConfirmTextbox.text == $Panel/PasswordTextbox.text:
			if await BackendConnectionManager.register_player($Panel/EmailTextbox.text, $Panel/PasswordTextbox.text, $Panel/UsernameTextbox.text):
				get_node("..").continue_loading()
			else:
				$Panel/InfoLabel.text = "Registration failed: invalid credentials."
		else:
			$Panel/InfoLabel.text = "Registration failed: password does not match confirmed password."
	else:
		$Panel/InfoLabel.text = "Registration failed: empty fields."

func _on_already_have_account_button_button_up() -> void:
	get_node("..").show_login_screen()
