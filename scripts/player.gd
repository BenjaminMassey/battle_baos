extends Node3D

var world_position: Vector3 = Vector3.ZERO;
var world_radius: float = 7.5;
var player_radius: float = 1.0;
var player_position: Vector3 = Vector3(0, world_radius + (player_radius * 0.5), 0);
var forward_vec: Vector3 = Vector3.RIGHT;
var rotation_speed: float = 0.5;
var turn_speed: float = 1.5;
var current_height: float = 0;
var jump_height: float = 0.15;
var jump_up_time: float = 1.0;
var jump_down_time: float = 1.0;
var jumping: bool = false;
var jump_tween;
var alive: bool = true;
var is_peer: bool = false;

func _process(delta: float) -> void:
	if !get_tree().get_root().find_child("main", true, false).game_running:
		return;
	if !alive || is_peer:
		return;
	var world_intersection = (global_position - world_position).normalized();
	if Input.is_action_pressed("turn_right"):
		forward_vec *= Quaternion(world_intersection, turn_speed * delta);
	if Input.is_action_pressed("turn_left"):
		forward_vec *= Quaternion(world_intersection, -turn_speed * delta);
	if Input.is_action_just_pressed("jump"):
		jump();
	var forward_rotation = Quaternion(forward_vec, rotation_speed * delta)
	player_position *= forward_rotation;
	var player_origin = player_position * (1.0 + current_height);
	transform.origin = player_origin;
	look_at(forward_rotation * player_origin);
	
func jump() -> void:
	if jumping:
		return;
	jumping = true;
	jump_tween = get_tree().create_tween();
	jump_tween.tween_property(self, "current_height", jump_height, jump_up_time);
	var jump_down = func():
		jump_tween = get_tree().create_tween();
		jump_tween.tween_property(self, "current_height", 0.0, jump_down_time);
		var jump_finish = func():
			jumping = false;
		jump_tween.tween_callback(jump_finish);
	jump_tween.tween_callback(jump_down);

func die() -> void:
	if !alive:
		return;
	alive = false;
	#var tween = get_tree().create_tween();
	#tween.tween_property(self, "scale", Vector3(0.25, 0.25, 0.25), 1);
	#TODO: really want a fade, actually, if anything
