extends Node

const MAX_CLIENTS = 2

func create_server(port: int) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var res: Error = peer.create_server(port, MAX_CLIENTS)
	
	if res == OK:
		print("Opened server at port " + str(port))
	else:
		print("Failure to create server: ", res)
	
	multiplayer.multiplayer_peer = peer
	
func join_server(ip_address: String, port: int) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var res: Error = peer.create_client(ip_address, port)
	if res == OK:
		print("Connected to " + ip_address + ":" + str(port))
	else:
		print("Failure to connect: ", res)
	multiplayer.multiplayer_peer = peer
