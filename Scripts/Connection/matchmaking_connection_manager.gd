extends Node

var request: HTTPRequest = HTTPRequest.new()
var polling_timer: Timer
var player_id: String = ""
var username: String = ""
var rating: int = 1000
var client_timer: Timer
var board_state
var board_data
var score: int = 0
var opponent_board_state
var opponent_score: int = 0
var time_left: int
var server_peer_id: int = -1

const MAX_CLIENTS: int = 2
var port: int = 7000
@export var levels_folder: String = "res://Assets/Levels"  # Path to the JSON file
var clients := []
var current_match_id: String = ""
var timer: Timer
var level_timer: Timer
var boards: Dictionary
var scores: Dictionary

func _ready() -> void:
	add_child(request)
	if OS.has_feature("dedicated_server"):
		print("Starting dedicated server...")
		timer = Timer.new()
		timer.wait_time = 0.5
		timer.autostart = true
		timer.one_shot = false
		timer.connect("timeout", _on_timer_timeout)
		call_deferred("add_child", timer)
		
		create_server(port)
	else:
		print("Starting client...")
		
func _on_timer_timeout() -> void:
	for peer_id in multiplayer.get_peers():
		var game_state = get_game_state(peer_id)
		rpc_id(peer_id, "_receive_game_state", game_state)

func join_server(ip_address: String, port: int) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_client(ip_address, port)
	multiplayer.multiplayer_peer = peer
	print("Client connected to peer with ID: ", multiplayer.multiplayer_peer.get_unique_id())

func start_matchmaking() -> void:
	print(BackendConnectionManager.player_data)
	player_id = str(BackendConnectionManager.player_id)
	username = BackendConnectionManager.player_data.get("username")
	rating = BackendConnectionManager.player_data.get("rating", 1000)
	
	send_matchmaking_request()
	
	
	if not polling_timer:
		polling_timer = Timer.new()
		polling_timer.wait_time = 2.0
		polling_timer.autostart = true
		polling_timer.timeout.connect(send_matchmaking_request)
		call_deferred("add_child", polling_timer)
	
func load_level_data() -> Dictionary:
	var level_data = {}
	var files = DirAccess.get_files_at(levels_folder)
	var level_file_path = files[randi_range(0, len(files))]
	var file = FileAccess.open(level_file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	var parsed_data = JSON.parse_string(json_text)
	if parsed_data.error == OK:
		level_data = parsed_data.result
	else:
		print("Error parsing JSON data:", parsed_data.error_string)
	
	file.close()
	return level_data

func send_matchmaking_request() -> void:
	var json_data = {
		"playerId": player_id,
		"username": username,
		"rating": rating
	}
	
	var json_string: String = JSON.stringify(json_data)
	var headers: Array = ["Content-Type: application/json"]
	
	if not request.request_completed.is_connected(_on_request_completed):
		request.request_completed.connect(_on_request_completed)
	
	request.request("http://localhost:3000/matchmaking/join", headers, HTTPClient.METHOD_POST, json_string)

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		print("Waiting for match...")
		var json_data = {
			"playerId": player_id
		}
		
		var json_string: String = JSON.stringify(json_data)
		var headers: Array = ["Content-Type: application/json"]
		var new_request: HTTPRequest = HTTPRequest.new()
		new_request.request_completed.connect( 
			func(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
				var json = JSON.new()
				json.parse(body.get_string_from_utf8())
				var new_response = json.get_data()
				if new_response.has("port"):
					
					var port: int = int(new_response["port"])
					var match_id: String = new_response["matchId"]
					
					print("Match found! Match ID: ", match_id)
					print("Connecting to port: ", port)
					
					# Stop polling
					if polling_timer:
						polling_timer.stop()
					
					# Connect to the game server
					join_server("localhost", port)
					board_data = null
					board_state = null
					score = 0
					opponent_score = 0
					opponent_board_state = null
					client_timer = Timer.new()
					client_timer.wait_time = 0.5
					client_timer.autostart = true
					client_timer.one_shot = false
					client_timer.connect("timeout", send_data_to_server)
					call_deferred("add_child", client_timer)
		)
		add_child(new_request)
		new_request.request("http://localhost:3000/match/check", headers, HTTPClient.METHOD_POST, json_string)
		
	elif response_code == 202:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		var response = json.get_data()
		
		if response and response.has("match"):
			var match_data = response["match"]
			var port: int = int(match_data["port"])
			var match_id: String = match_data.get("matchId", "unknown")
			var players: Array = match_data.get("players", [])
			
			print("Match found! Match ID: ", match_id)
			print("Players: ", players)
			print("Connecting to port: ", port)
			
			if polling_timer:
				polling_timer.stop()
			
			join_server("localhost", port)
			board_data = null
			board_state = null
			score = 0
			opponent_score = 0
			opponent_board_state = null
			client_timer = Timer.new()
			client_timer.wait_time = 0.5
			client_timer.autostart = true
			client_timer.one_shot = false
			client_timer.connect("timeout", send_data_to_server)
			call_deferred("add_child", client_timer)
		else:
			print("Invalid match response structure")
	else:
		print("Matchmaking error - Response code: ", response_code)
		print("Response: ", body.get_string_from_utf8())

func send_data_to_server() -> void:
	if server_peer_id != -1:
		var player_data = {}
		player_data["id"] = player_id
		player_data["board_state"] = board_state
		player_data["score"] = score
		rpc_id(server_peer_id, "receive_player_data", player_data)
		

@rpc
func _receive_level_data(level_json: String) -> void:
	var level_data = JSON.parse_string(level_json)
	print("Received level data: ", level_data)
	
	board_data = level_data
	get_tree().change_scene_to_file("res://Scenes/Level/multiplayer_level.tscn")

@rpc
func _receive_game_state(game_state: Dictionary) -> void:
	opponent_score = game_state["opponent_score"]
	opponent_board_state = game_state["opponent_board"]
	
@rpc
func _receive_level_end(final_score: int, final_opponent_score: int) -> void:
	score = final_score
	opponent_score = final_opponent_score
	get_tree().change_scene_to_file("res://Scenes/Menus/EndScreens/multiplayer_end_screen.tscn")

func get_game_state(peer_id: int) -> Dictionary:
	var game_state = {}
	game_state["opponent_board"] = get_board_state(get_opponent_id(peer_id))  # Get the opponent's board state
	game_state["opponent_score"] = get_score(get_opponent_id(peer_id))
	game_state["time_left"] = int(floor(timer.time_left))

	return game_state

func get_board_state(peer_id: int) -> Array:
	return boards[peer_id]

func get_score(peer_id: int) -> int:
	return scores[peer_id]
		
func get_opponent_id(peer_id: int) -> int:
	# Assuming you have exactly two players
	return 1 if peer_id == 0 else 0 

# Start the server
func create_server(port: int) -> void:
	var peer = ENetMultiplayerPeer.new()
	var res = peer.create_server(port, MAX_CLIENTS)

	if res == OK:
		print("Opened server at port " + str(port))
		# Set the multiplayer peer (server)
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		multiplayer.multiplayer_peer = peer
		server_peer_id = get_tree().get_multiplayer().get_unique_id()
	else:
		print("Error creating server:", res)

func _on_peer_connected(peer_id: int) -> void:
	print("Peer connected: " + str(peer_id))
	print("Current peer count: " + str(len(multiplayer.get_peers())))
	if OS.has_feature("dedicated_server"):
		if len(multiplayer.get_peers()) == 1:
			server_peer_id = multiplayer.get_peers()[0]
		if len(multiplayer.get_peers()) == MAX_CLIENTS:
			
			var level_data = load_level_data()
			_send_level_data_to_clients(level_data)
			
			level_timer = Timer.new()
			level_timer.wait_time = 90
			level_timer.autostart = true
			level_timer.one_shot = true
			level_timer.connect("timeout", _on_level_timer_timeout)
			call_deferred("add_child", level_timer)

func _on_level_timer_timeout():
	for peer_id in multiplayer.get_peers():
		rpc_id(peer_id, '_receive_level_end', scores[peer_id], scores[get_opponent_id(peer_id)])

func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer " + str(peer_id) + " has disconnected")
	if OS.has_feature("dedicated_server"):
		if len(multiplayer.get_peers()) == 0:
			var json_data = {
				"matchId": current_match_id
			}
			var headers: Array = ["Content-Type: application/json"]
			var json_string = JSON.stringify(json_data)
			var request: HTTPRequest = HTTPRequest.new()
			request.request("http://localhost:3000/match/finalize", headers, HTTPClient.METHOD_POST, json_string)

func _send_level_data_to_clients(data: Dictionary) -> void:
	var level_json = JSON.stringify(data)
	for peer_id in multiplayer.get_peers():
		rpc_id(peer_id, "_receive_level_data", level_json)

func _send_id_to_clients(id: int):
	for peer_id in multiplayer.get_peers():
		rpc_id(peer_id, "receive_server_id", id)

@rpc
func receive_player_data(player_data: Dictionary) -> void:
	boards[player_data["id"]] = player_data["board_state"]
	scores[player_data["id"]] = player_data["score"]
	
@rpc 
func receive_server_id(id: int) -> void:
	server_peer_id = id
