extends Node3D

@export var player: Player;
var trail_point = preload("res://scenes/trail_point.tscn");

var positions = {}; # HashSet as a Dict
var points: Array[Node3D] = [];

func _ready() -> void:
	pass;

func _on_timer_timeout() -> void:
	if self.player.player_type == Player.Type.Host and (Global.state != Global.State.Game or self.player.player_state != Player.State.Playing):
		return;
	make_point(self.player.transform.origin);

func make_point(pos: Vector3) -> void:
	if self.positions.has(pos):
		return;
	else:
		self.positions[pos] = null; # emulating hashset: value doesn't matter
	var point = self.trail_point.instantiate();
	self.points.append(point);
	get_tree().get_root().add_child(point); #TODO: add somewhere better
	point.transform.origin = pos;
	player_align(point);
	enable_delay(point);

func player_align(point: Node3D):
	var timer = Timer.new();
	point.add_child(timer);
	timer.autostart = true;
	timer.one_shot = true;
	timer.wait_time = 0.05;
	var look = func():
		point.look_at(self.player.global_position, self.player.player_data["forward"]);
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
	if self.player.player_type == Player.Type.Host:
		self.player.die();

func destroy_points() -> void:
	for point in self.points:
		point.queue_free();
	self.points.clear();
	self.positions.clear();
	
