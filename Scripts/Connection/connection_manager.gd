extends Node

const MAX_CLIENTS: int = 2
const SERVER_PORT: int = 9876

func _ready() -> void:
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
