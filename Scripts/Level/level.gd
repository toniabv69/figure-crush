extends Node2D

var score: int = 0

func _process(delta: float) -> void:
	$TimerLabel.text = str(floor(int($Timer.time_left)))
	update_score_label()

func _add_score(added_score: int) -> void:
	score += added_score
	update_score_label()

func update_score_label() -> void:
	$ScoreLabel.text = "Score: " + str(score)

func _on_timer_timeout() -> void:
	MatchmakingConnectionManager.score = score
	get_tree().change_scene_to_file("res://Scenes/Menus/EndScreens/end_screen.tscn")

	
