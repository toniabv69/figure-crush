extends Node2D

var score: int = 0
var opponent_score: int = 0


func _ready():
	score = MatchmakingConnectionManager.score
	opponent_score = MatchmakingConnectionManager.opponent_score
	$Score.text = score
	if score > opponent_score:
		$OutcomeLabel.text = "You Won!"
		BackendConnectionManager.player_data["rating"] += 30
		BackendConnectionManager.update_rating(BackendConnectionManager.player_data["rating"])
		$Rating.text = "Rating: " + str(BackendConnectionManager.player_data["rating"]) + " (+30)"
	elif score < opponent_score:
		$OutcomeLabel.text = "You Lost!"
		BackendConnectionManager.player_data["rating"] -= 30
		BackendConnectionManager.update_rating(BackendConnectionManager.player_data["rating"])
		$Rating.text = "Rating: " + str(BackendConnectionManager.player_data["rating"]) + " (-30)"

	

func _on_button_button_up():
	get_tree().change_scene_to_file("res://Scenes/Menus/main_menu.tscn")
