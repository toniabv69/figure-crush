extends Node2D

var score: int = 0
var opponent_score: int = 0
var time_left: int = 0
var opponent_board: Board
var board_data
var timer: Timer
var piece_scene: PackedScene = preload("res://Scenes/Objects/Pieces/piece.tscn")

func _ready():
	setup_board()
	timer = Timer.new()
	timer.wait_time = 0.5  # Half a second
	timer.autostart = true
	timer.one_shot = false  # Repeated calls every 0.5 seconds
	timer.connect("timeout", send_data_to_matchmaker)
	%Board.multiplayer_on = true

func _process(delta: float) -> void:
	$TimerLabel.text = str(floor(int(time_left)))
	update_score_label()

func send_data_to_matchmaker():
	MatchmakingConnectionManager.score = score
	var board_state = []
	for x in %Board.width:
		for y in %Board.height:
			var space_data = {}
			space_data["x"] = x
			space_data["y"] = y
			space_data["blocked"] = %Board.spaces[x][y].blocked
			space_data["piece_type"] = %Board.spaces[x][y].piece.type if %Board.spaces[x][y].piece else null
			space_data["piece_special"] = %Board.spaces[x][y].piece.special if %Board.spaces[x][y].piece else null
			board_state.append(space_data)
	MatchmakingConnectionManager.board_state = board_state
	get_matchmaker_data()

func get_matchmaker_data():
	update_opponent_score(MatchmakingConnectionManager.opponent_score)
	update_opponent_board(MatchmakingConnectionManager.opponent_board_state)
	update_timer_label(MatchmakingConnectionManager.time_left)
	
func update_opponent_board(board_state):
	var opponent_board = %OpponentBoard
	for column in opponent_board.spaces:
		for space in column:
			if space.piece and not space.blocked:
				space.piece.queue_free()
				space.piece = null
	
	for entry in board_state:
		if not entry["blocked"]:
			var new_piece = piece_scene.instantiate()
			new_piece.type = entry["piece_type"]
			new_piece.special = entry["piece_special"]
			opponent_board.place_piece(opponent_board.spaces[entry["x"]][entry["y"]], new_piece)
			
func update_timer_label(time_left: int):
	$TimerLabel.text = str(time_left)

func _add_score(added_score: int) -> void:
	score += added_score
	update_score_label()

func update_opponent_score(new_score: int) -> void:
	opponent_score = new_score
	$OpponentScoreLabel.text = "Score: " + str(opponent_score)

func update_score_label() -> void:
	$ScoreLabel.text = "Score: " + str(score)
	
func set_board_data(incoming_data):
	board_data = incoming_data

func setup_board():
	$Board.set_width(board_data["width"])
	$Board.set_height(board_data["height"])
	$Board.set_blocked(board_data["blocked"])
	$Board.start()
