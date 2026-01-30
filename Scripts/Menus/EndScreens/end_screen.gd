extends Node2D

var score: int = 0

func _ready():
	score = MatchmakingConnectionManager.score
	$Score.text = "Score: " + str(score)

func _on_button_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/main_menu.tscn")
