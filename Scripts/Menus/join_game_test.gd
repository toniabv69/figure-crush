extends Node2D

func _on_join_button_pressed() -> void:
	ConnectionManager.join_server($IPAddressTextbox.text, int($PortTextbox.text))
