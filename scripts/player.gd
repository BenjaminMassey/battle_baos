extends Node3D

var world_radius: float = 7.5;
var player_radius: float = 1.0;
var player_position: Vector3 = Vector3(0, world_radius + (player_radius * 0.5), 0);
var forward_vec: Vector3 = Vector3.RIGHT;
var rotation_speed: float = 0.5;
var turn_speed: float = 1.5;

func _process(delta: float) -> void:
	if Input.is_action_pressed("turn_right"):
		forward_vec *= Quaternion(Vector3.UP, turn_speed * delta);
	if Input.is_action_pressed("turn_left"):
		forward_vec *= Quaternion(Vector3.UP, -turn_speed * delta);
	player_position *= Quaternion(forward_vec, rotation_speed * delta);
	transform.origin = player_position;
	look_at(Quaternion(forward_vec, rotation_speed * delta) * player_position);
