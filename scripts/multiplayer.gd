extends Node

@export var player: Node3D;

var udp := PacketPeerUDP.new()
var server_address = "127.0.0.1"
var server_port = 8081
var game_id = "42069"

func _ready():
	return; # TODO: make real
	udp.connect_to_host(server_address, server_port)

func _process(delta):
	return; # TODO: make real
	var message: Dictionary = {
		"game_id": game_id,
		"player_id": player.name,
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
