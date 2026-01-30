extends Node2D

var request: HTTPRequest = HTTPRequest.new()

func _ready():
	if not OS.has_feature("dedicated_server"):
		$InfoLabel.text = "Loading Stored Credentials..."
		await BackendConnectionManager.load_stored_credentials()
		if BackendConnectionManager.stored_token:
			var email: String = BackendConnectionManager.player_data.get("email")
			if await BackendConnectionManager.check_email_available(email) == true:
				show_login_screen()
			else:
				continue_loading()
		else:
			show_login_screen()
	
func show_login_screen():
	$TitleLabel.hide()
	$InfoLabel.hide()
	$LoginScreen.show()
	$RegisterScreen.hide()
	
func show_register_screen():
	$TitleLabel.hide()
	$InfoLabel.hide()
	$LoginScreen.hide()
	$RegisterScreen.show()

func continue_loading():
	$TitleLabel.show()
	$InfoLabel.show()
	$LoginScreen.hide()
	$RegisterScreen.hide()
	$InfoLabel.text = "Retrieving Player Data..."
	await BackendConnectionManager.get_player_profile()
	get_tree().change_scene_to_file("res://Scenes/Menus/main_menu.tscn")
