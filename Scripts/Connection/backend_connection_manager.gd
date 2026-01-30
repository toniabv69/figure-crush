extends Node

const API_URL: String = "http://16.16.195.24:5000/api/players"
var stored_token: String = ""
var player_data: Dictionary = {}
var player_id: int = -1

func load_stored_credentials():
	var file: FileAccess = FileAccess.open("user://player_token.json", FileAccess.READ)
	if file:
		var data: Variant = JSON.parse_string(file.get_as_text())
		stored_token = data.get("token", "")
		player_data = data.get("player", {})
		player_id = player_data.get("id", -1)

func save_credentials(token: String, player: Dictionary):
	var data: Dictionary = {
		"token": token,
		"player": player
	}
	var file: FileAccess = FileAccess.open("user://player_token.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	stored_token = token
	player_data = player
	player_id = player.get("id", -1)

func register_player(email: String, password: String, username: String = ""):
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	var json: String = JSON.stringify({
		"email": email,
		"password": password,
		"username": username if username != "" else null
	})
	http.request(API_URL + "/register", ["Content-Type: application/json"], HTTPClient.METHOD_POST, json)
	
	var response = await http.request_completed
	var result: Variant = JSON.parse_string(response[3].get_string_from_utf8())
	http.queue_free()
	
	if result == null:
		return false
	
	if result.has("token"):
		save_credentials(result["token"], result["player"])
		print("Registration successful")
		return true
	else:
		print("Registration failed: ", result.get("error", "Unknown error"))
		return false

func login_player(email: String, password: String):
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	var json: String = JSON.stringify({"email": email, "password": password})
	http.request(API_URL + "/login", ["Content-Type: application/json"], HTTPClient.METHOD_POST, json)
	
	var response = await http.request_completed
	var result: Variant = JSON.parse_string(response[3].get_string_from_utf8())
	http.queue_free()
	
	if result.has("token"):
		save_credentials(result["token"], result["player"])
		print("Login successful")
		return true
	else:
		print("Login failed: ", result.get("error", "Invalid credentials"))
		return false

func check_email_available(email: String):
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	http.request(API_URL + "/check-email/" + email, ["Content-Type: application/json"], HTTPClient.METHOD_GET)
	
	var response = await http.request_completed
	var result: Variant = JSON.parse_string(response[3].get_string_from_utf8())
	http.queue_free()
	
	return result.get("available", false)

func get_player_profile():
	if player_id == -1:
		print("Not authenticated")
		return null
	
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	var headers: Array = ["Content-Type: application/json", "Authorization: Bearer " + stored_token]
	http.request(API_URL + "/%d" % player_id, headers, HTTPClient.METHOD_GET)
	
	var response = await http.request_completed
	var result: Variant = JSON.parse_string(response[3].get_string_from_utf8())
	http.queue_free()
	
	if result.has("player"):
		player_data = result["player"]
		print("Profile loaded")
		return result["player"]
	else:
		print("Failed to load profile")
		return null

func update_rating(new_rating: int):
	if player_id == -1:
		print("Not authenticated")
		return false
	
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	var json: String = JSON.stringify({"rating": new_rating})
	var headers: Array = ["Content-Type: application/json", "Authorization: Bearer " + stored_token]
	http.request(API_URL + "/%d/rating" % player_id, headers, HTTPClient.METHOD_PUT, json)
	
	var response = await http.request_completed
	var _result: Variant = JSON.parse_string(response[3].get_string_from_utf8())
	http.queue_free()
	
	if response[1] == 200:
		player_data["rating"] = new_rating
		print("Rating updated to %d" % new_rating)
		return true
	else:
		print("Failed to update rating")
		return false

func delete_account(password: String):
	if player_id == -1:
		print("Not authenticated")
		return false
	
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	var json: String = JSON.stringify({"password": password})
	var headers: Array = ["Content-Type: application/json", "Authorization: Bearer " + stored_token]
	http.request(API_URL + "/%d" % player_id, headers, HTTPClient.METHOD_DELETE, json)
	
	var response = await http.request_completed
	var result: Variant = JSON.parse_string(response[3].get_string_from_utf8())
	http.queue_free()
	
	if response[1] == 200:
		stored_token = ""
		player_data = {}
		player_id = -1
		print("Account deleted")
		return true
	else:
		print("Delete failed: ", result.get("error", "Invalid password"))
		return false

func logout():
	stored_token = ""
	player_data = {}
	player_id = -1
	print("Logged out")

func make_api_request(endpoint: String, method: int = HTTPClient.METHOD_GET, body: String = ""):
	if player_id == -1:
		print("Not authenticated")
		return {}
	
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	var headers: Array = ["Content-Type: application/json", "Authorization: Bearer " + stored_token]
	http.request(API_URL + endpoint, headers, method, body)
	
	var response = await http.request_completed
	var result: Variant = JSON.parse_string(response[3].get_string_from_utf8())
	http.queue_free()
	
	return result
