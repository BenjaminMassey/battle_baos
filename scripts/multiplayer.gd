extends Node

@export var player: Node3D;

var connected = false;
var udp := PacketPeerUDP.new()
var server_address = "127.0.0.1"
var http_port = 8080
var udp_port = 8081
var game_id = ""
var player_name = ""

func _process(delta):
	if !%main.game_running:
		return;
	if !connected:
		udp.connect_to_host(server_address, udp_port)
		connected = true;
	var message: Dictionary = {
		"game_id": game_id,
		"player_id": player_name,
		"state": {
			"alive": true,
			"position": [player.global_position.x, player.global_position.y, player.global_position.z],
			"rotation": [player.rotation.x, player.rotation.y, player.rotation.z]
		}
	}
	udp.put_packet(JSON.stringify(message).to_utf8_buffer())
	print("Sent to server: ", message)
	
	if udp.get_available_packet_count() > 0:
		var response = udp.get_packet()
		if response != null:
			var data = JSON.parse_string(response.get_string_from_utf8());
			print("Received from server: ", data)
		else:
			print("Failed to parse MessagePack response")


func _on_create_button_pressed() -> void:
	print("create button");
	game_id = %gui.find_child("input").find_child("room_edit").text;
	player_name = %gui.find_child("input").find_child("player_edit").text;
	%gui.find_child("input").find_child("info_text").text = "Creating room...";
	var auth = FileAccess.open("res://auth.key", FileAccess.READ).get_as_text();
	var data = {
		"auth_key": auth,
		"room_id": game_id
	};
	var json = JSON.stringify(data);
	var url = "http://" + server_address + ":" + str(http_port) + "/createRoom";
	var headers = ["Content-Type: application/json"];
	$HTTPRequest.request(url ,headers, HTTPClient.METHOD_POST, json);

func _on_join_button_pressed() -> void:
	print("join button");
	game_id = %gui.find_child("input").find_child("room_edit").text;
	player_name = %gui.find_child("input").find_child("player_edit").text;
	%main.show_game();
	%main.game_running = true;
	# TODO: verify game exists, like at all


func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		%main.show_game();
		%main.game_running = true;
	else:
		var message = body.get_string_from_utf8();
		if message.is_empty() and response_code == 0:
			message = "Connection timed out.";
		print("[", response_code, "] ", message);
		%gui.find_child("input").find_child("info_text").text = message;
