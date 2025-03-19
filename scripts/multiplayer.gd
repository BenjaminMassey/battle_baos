extends Node

@export var player: Player;

var player_scene = preload("res://scenes/player.tscn")

var connected = false;
var udp := PacketPeerUDP.new();
var server_address = "127.0.0.1";
var http_port = 8080;
var udp_port = 8081;
var room_id = "";
var player_name = "";
var position_tweens: Dictionary;

func _process(delta):
	if Global.state != Global.State.Game:
		return;
	if !self.connected:
		self.udp.connect_to_host(self.server_address, self.udp_port)
		self.connected = true;
	var player_message: Dictionary = {
		"room_id": self.room_id,
		"player_id": self.player_name,
		"state": {
			"alive": self.player.player_state != Player.State.Dead,
			"position": [self.player.global_position.x, self.player.global_position.y, self.player.global_position.z],
			"rotation": [self.player.rotation.x, self.player.rotation.y, self.player.rotation.z]
		}
	}
	var out_message: Dictionary = {
		"tag": "player_message",
		"data": JSON.stringify(player_message)
	};
	self.udp.put_packet(JSON.stringify(out_message).to_utf8_buffer())
	#print("Sent to server: ", message)
	
	if self.udp.get_available_packet_count() > 0:
		var response = self.udp.get_packet()
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
		if name == self.player_name:
			var player_index = int(data["state"]["data"][name]["index"]);
			self.player.player_data["spawn"] = Global.player_spawn_points[player_index];
			continue;
		var peer = get_node(name);
		if peer == null:
			peer = player_scene.instantiate();
			add_child(peer);
			peer.name = name;
			peer.player_type = Player.Type.Peer;
			%gui.find_child("log").message("Player \"" + name + "\" joined."); # TODO: better easier logging
			#TODO: don't really wanna force reset, should be waiting state
			self.player.reset();
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
	if dead_count == get_child_count() and player.player_state != Player.State.Waiting: # TODO: other player states?
		print("RESET TIME");
		self.player.reset();
		self.player.player_state = Player.State.Waiting;
		for child in get_children():
			if child.name == "HTTPRequest":
				continue; #TODO: exclude HTTPRequest better ahh
			child.reset();
			child.player_state = Player.State.Waiting;
	
func _on_create_button_pressed() -> void:
	print("create button");
	self.room_id = %menu.find_child("input").find_child("room_edit").text;
	self.player_name = %menu.find_child("input").find_child("player_edit").text;
	%menu.find_child("input").find_child("info_text").text = "Creating room...";
	var auth = FileAccess.open("res://auth.key", FileAccess.READ).get_as_text();
	var data = {
		"auth_key": auth,
		"room_id": self.room_id
	};
	var json = JSON.stringify(data);
	var url = "http://" + self.server_address + ":" + str(self.http_port) + "/createRoom";
	var headers = ["Content-Type: application/json"];
	$HTTPRequest.request(url, headers, HTTPClient.METHOD_POST, json);
# TODO: less reliance on % and find_child calls

func _on_join_button_pressed() -> void:
	print("join button");
	self.room_id = %menu.find_child("input").find_child("room_edit").text;
	self.player_name = %menu.find_child("input").find_child("player_edit").text;
	%menu.find_child("input").find_child("info_text").text = "Joining room...";
	var auth = FileAccess.open("res://auth.key", FileAccess.READ).get_as_text();
	var data = {
		"auth_key": auth,
		"room_id": self.room_id
	};
	var json = JSON.stringify(data);
	var url = "http://" + self.server_address + ":" + str(self.http_port) + "/checkRoom";
	var headers = ["Content-Type: application/json"];
	$HTTPRequest.request(url, headers, HTTPClient.METHOD_GET, json);
# TODO: less reliance on % and find_child calls
# TODO: very similar to create button: simplify

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200 and (body.get_string_from_utf8() == "Room exists." or body.get_string_from_utf8() == "Room created.") : # TODO: better
		Global.state = Global.State.Game;
		%menu.hide();
		# TODO: combine two lines above via global-style signal-ing
		self.player.player_state = Player.State.Waiting;
	else:
		var message = body.get_string_from_utf8();
		if message.is_empty() and response_code == 0:
			message = "Connection timed out.";
		print("[", response_code, "] ", message);
		%menu.find_child("input").find_child("info_text").text = message;
# TODO: less reliance on % and find_child calls
