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
			"alive": player.alive,
			"position": [player.global_position.x, player.global_position.y, player.global_position.z],
			"rotation": [player.rotation.x, player.rotation.y, player.rotation.z]
		}
	}
	var out_message: Dictionary = {
		"tag": "player_message",
		"data": JSON.stringify(player_message)
	};
	udp.put_packet(JSON.stringify(out_message).to_utf8_buffer())
	#print("Sent to server: ", message)
	
	if udp.get_available_packet_count() > 0:
		var response = udp.get_packet()
		if response != null:
			var in_message = JSON.parse_string(response.get_string_from_utf8());
			#print("Received from server: ", in_message)
			if in_message != null:
				handle_udp(in_message);
			else:
				print("Failed to parse UDP response");
		else:
			print("Failed to get UDP response");

func handle_udp(message: Dictionary):
	if !message.has("tag"):
		print("no tag in message: skipping");
		return;
	var tag = message["tag"];
	var data = message["data"];
	if tag == "game_state":
		handle_states(JSON.parse_string(data));
	elif tag == "error":
		print("Error UDP response: ", data);
	else:
		print("Unhandled UDP tag: ", tag);

func handle_states(data: Dictionary):
	var dead_count = 0;
	var player_names = data["state"]["names"];
	for name in player_names:
		var state = data["state"]["data"][name]["state"];
		if !state["alive"]:
			dead_count += 1;
		if name == player_name:
			var player_index = int(data["state"]["data"][name]["index"]);
			player.player_spawn = player.player_spawns[player_index];
			continue;
		var peer = get_node(name);
		if peer == null:
			peer = player_scene.instantiate();
			add_child(peer);
			peer.name = name;
			peer.is_peer = true;
			%gui.find_child("log").message("Player \"" + name + "\" joined.");
			#TODO: don't really wanna force reset, should be waiting state
			player.reset();
			for child in get_children():
				if child.name == "HTTPRequest":
					continue; #TODO: exclude HTTPRequest better ahh
				child.reset();
		if state["alive"]:
			if position_tweens.has(name):
				position_tweens[name].kill();
			position_tweens[name] = get_tree().create_tween()
			position_tweens[name].tween_property(peer, "global_position", Vector3(state["position"][0], state["position"][1], state["position"][2]), 0.05)
			#peer.global_position = Vector3(state["position"][0], state["position"][1], state["position"][2]);
			peer.rotation = Vector3(state["rotation"][0], state["rotation"][1], state["rotation"][2]);
		else:
			peer.die();
	for child in get_children():
		if child.name == "HTTPRequest":
			continue; #TODO: exclude HTTPRequest better ahh
		if child.name not in player_names:
			%gui.find_child("log").message("Player \"" + child.name + "\" left.");
			child.queue_free();
	if dead_count == get_child_count() and !player.countdown_running:
		print("RESET TIME");
		player.reset();
		for child in get_children():
			if child.name == "HTTPRequest":
				continue; #TODO: exclude HTTPRequest better ahh
			child.reset();
			child.alive = true; #TODO: shouldn't be needed
	
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
