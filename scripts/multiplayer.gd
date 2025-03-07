extends Node

@export var player: Node3D;

var player_scene = preload("res://scenes/player.tscn")

var connected = false;
var udp := PacketPeerUDP.new()
var server_address = "127.0.0.1"
var http_port = 8080
var udp_port = 8081
var room_id = ""
var player_name = ""
var position_tweens: Dictionary;

func _process(delta):
	if !%main.game_running:
		return;
	if !connected:
		udp.connect_to_host(server_address, udp_port)
		connected = true;
	var player_message: Dictionary = {
		"room_id": room_id,
		"player_id": player_name,
		"state": {
			"alive": true,
			"position": [player.global_position.x, player.global_position.y, player.global_position.z],
			"rotation": [player.rotation.x, player.rotation.y, player.rotation.z]
		}
	}
	var message: Dictionary = {
		"tag": "player_message",
		"data": JSON.stringify(player_message)
	};
	udp.put_packet(JSON.stringify(message).to_utf8_buffer())
	#print("Sent to server: ", message)
	
	if udp.get_available_packet_count() > 0:
		var response = udp.get_packet()
		if response != null:
			var data = JSON.parse_string(response.get_string_from_utf8());
			#print("Received from server: ", data)
			if response != null:
				update_states(data);
			else:
				print("Failed to parse UDP response");
		else:
			print("Failed to get UDP response");

func update_states(data: Dictionary):
	var player_names = data["state"]["names"];
	for name in player_names:
		if name == player_name:
			continue;
		var state = data["state"]["data"][name]["state"];
		var peer = get_node(name);
		if peer == null:
			peer = player_scene.instantiate();
			peer.name = name;
			add_child(peer);
			%gui.find_child("log").message("Player \"" + name + "\" joined.");
		if state["alive"]:
			if position_tweens.has(name):
				position_tweens[name].kill();
			position_tweens[name] = get_tree().create_tween()
			position_tweens[name].tween_property(peer, "global_position", Vector3(state["position"][0], state["position"][1], state["position"][2]), 0.05)
			#peer.global_position = Vector3(state["position"][0], state["position"][1], state["position"][2]);
			peer.rotation = Vector3(state["rotation"][0], state["rotation"][1], state["rotation"][2]);
		else:
			pass; #TODO: apply some dead state
	for child in get_children():
		if child.name == "HTTPRequest":
			continue; #TODO: shouldn't need exceptions, do better check
		if child.name not in player_names:
			%gui.find_child("log").message("Player \"" + child.name + "\" left.");
			child.queue_free();

func _on_create_button_pressed() -> void:
	print("create button");
	room_id = %menu.find_child("input").find_child("room_edit").text;
	player_name = %menu.find_child("input").find_child("player_edit").text;
	%menu.find_child("input").find_child("info_text").text = "Creating room...";
	var auth = FileAccess.open("res://auth.key", FileAccess.READ).get_as_text();
	var data = {
		"auth_key": auth,
		"room_id": room_id
	};
	var json = JSON.stringify(data);
	var url = "http://" + server_address + ":" + str(http_port) + "/createRoom";
	var headers = ["Content-Type: application/json"];
	$HTTPRequest.request(url, headers, HTTPClient.METHOD_POST, json);

func _on_join_button_pressed() -> void:
	print("join button");
	room_id = %menu.find_child("input").find_child("room_edit").text;
	player_name = %menu.find_child("input").find_child("player_edit").text;
	%menu.find_child("input").find_child("info_text").text = "Joining room...";
	var auth = FileAccess.open("res://auth.key", FileAccess.READ).get_as_text();
	var data = {
		"auth_key": auth,
		"room_id": room_id
	};
	var json = JSON.stringify(data);
	var url = "http://" + server_address + ":" + str(http_port) + "/checkRoom";
	var headers = ["Content-Type: application/json"];
	$HTTPRequest.request(url, headers, HTTPClient.METHOD_GET, json);

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		%main.show_game();
		%main.game_running = true;
	else:
		var message = body.get_string_from_utf8();
		if message.is_empty() and response_code == 0:
			message = "Connection timed out.";
		print("[", response_code, "] ", message);
		%menu.find_child("input").find_child("info_text").text = message;
