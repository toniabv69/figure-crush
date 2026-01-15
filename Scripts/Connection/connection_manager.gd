extends Node

const MAX_CLIENTS: int = 2
const SERVER_PORT: int = 9876

var request: HTTPRequest = HTTPRequest.new()

func _ready() -> void:
	add_child(request)
	if OS.has_feature("dedicated_server"):
		print("Starting dedicated server...")
		create_server(SERVER_PORT)

func create_server(port: int) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var res: Error = peer.create_server(port, MAX_CLIENTS)
	
	if res == OK:
		print("Opened server at port " + str(port))
	else:
		print("Failure to create server: ", res)
	
	multiplayer.peer_connected.connect(
		func(peer_id: int) -> void:
			print("Peer " + str(peer_id) + " has connected")
	)
	
	multiplayer.peer_disconnected.connect(
		func(peer_id: int) -> void:
			print("Peer " + str(peer_id) + " has disconnected")
	)
	
	multiplayer.multiplayer_peer = peer
	
func join_server(ip_address: String, port: int) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var res: Error = peer.create_client(ip_address, port)
	
	if res == OK:
		print("Connected to " + ip_address + ":" + str(port))
	else:
		print("Failure to connect: ", res)
		
	multiplayer.multiplayer_peer = peer
	
func send_matchmaking_request(json_data: Variant) -> void:
	var json_string: String = JSON.stringify(json_data)
	var headers: Array = ["Content-Type: application/json"]
	if not request.request_completed.is_connected(_on_request_completed_join):
		request.request_completed.connect(_on_request_completed_join)
	
	request.request("http://localhost:3000/matchmaking/join", headers, HTTPClient.METHOD_POST, json_string)

func _on_request_completed_join(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var timer: Timer = Timer.new()
		timer.wait_time = 2
		timer.one_shot = false
		timer.timeout.connect(send_matchmaking_request)
	elif response_code == 202:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		var response = json.get_data()
		print(response)
		join_server("localhost", int(response["match"]["port"]))
	else:
		print("a")
	
	
	
	
	
	
