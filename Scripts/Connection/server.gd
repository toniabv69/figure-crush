extends Node
class_name Server

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
	if OS.has_feature("dedicated_server"):
		print("Starting dedicated server...")
		timer = Timer.new()
		timer.wait_time = 0.5  # Half a second
		timer.autostart = true
		timer.one_shot = false  # Repeated calls every 0.5 seconds
		timer.connect("timeout", _on_timer_timeout)
		add_child(timer)  # Add timer as a child of the server
		
		create_server(port)
		
func _on_timer_timeout() -> void:
	# Prepare the data to send (you can modify this to send any game state data)
	for peer_id in multiplayer.get_peers():
		# Send board data (both player's and opponent's)
		var game_state = get_game_state(peer_id)
		rpc_id(peer_id, "_receive_game_state", game_state)

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
		
# Example function to load the level data from a JSON file
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
	else:
		print("Error creating server:", res)

# Handle a new client connection
func _on_peer_connected(peer_id: int) -> void:
	print("Peer connected: " + str(peer_id))

	# If both clients are connected, send them the level data
	if multiplayer.get_peer_count() == MAX_CLIENTS:
		var level_data = load_level_data()  # Load level data from JSON file
		_send_level_data_to_clients(level_data)
		level_timer = Timer.new()
		level_timer.wait_time = 90  # Half a second
		level_timer.autostart = true
		level_timer.one_shot = false  # Repeated calls every 0.5 seconds
		level_timer.connect("timeout", _on_level_timer_timeout)

func _on_level_timer_timeout():
	for peer_id in multiplayer.get_peers():
		rpc_id(peer_id, '_receive_level_end', scores[peer_id], scores[get_opponent_id(peer_id)])

# Handle a client disconnection
func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer " + str(peer_id) + " has disconnected")
	if multiplayer.get_peer_count() == 0:
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

@rpc
func receive_player_data(player_data: Dictionary) -> void:
	boards[player_data["id"]] = player_data["board_state"]
	scores[player_data["id"]] = player_data["score"]


	# You can use this data to create the level in the client scene
	# Example:
	# - Set the board dimensions: level_data["width"], level_data["height"]
	# - Block cells at positions in level_data["blocked"]
