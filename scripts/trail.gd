extends Node3D

@export var player: Node3D;

var trail_point = preload("res://scenes/trail_point.tscn");
var points: Array[Node3D] = [];

var main_node;
var player_node;

func _ready() -> void:
	main_node = get_tree().get_root().find_child("main", true, false);
	player_node = get_tree().get_root().find_child("player", true, false);

func _on_timer_timeout() -> void:
	if player.is_peer:
		print(main_node.game_running, ".", player_node.countdown_running, ".", player.alive);
	if !main_node.game_running or player_node.countdown_running or (!player.alive and !player.is_peer):
		return;
	var point = trail_point.instantiate();
	points.append(point);
	get_tree().get_root().add_child(point);
	point.transform.origin = player.transform.origin;
	player_align(point);
	enable_delay(point);

func player_align(point: Node3D):
	var timer = Timer.new();
	point.add_child(timer);
	timer.autostart = true;
	timer.one_shot = true;
	timer.wait_time = 0.05;
	var look = func():
		point.look_at(player.global_position, player.forward_vec);
	timer.connect("timeout", look);
	timer.start();

func enable_delay(point: Node3D):
	var collider = point.find_child("area").find_child("collider");
	collider.disabled = true;
	var timer = Timer.new();
	point.add_child(timer);
	timer.autostart = true;
	timer.one_shot = true;
	timer.wait_time = 0.25;
	var enable = func():
		collider.disabled = false;
	timer.connect("timeout", enable);
	timer.start();

func _on_area_area_entered(area: Area3D) -> void:
	if !player.is_peer:
		player.die();

func destroy_points() -> void:
	for point in points:
		point.queue_free();
	points.clear();
