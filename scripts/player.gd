extends Node3D

class_name Player;

enum Type {
	Host, ## player actually being controlled by this instance of the game
	Peer, ## an entity created and managed by multiplayer.gd
};
var player_type = Type.Host; # changed by multiplayer.gd for peers

enum State {
	Playing, ## in an active game, and alive, so actively moving+doing
	Waiting, ## in a game, but waiting for it to start
	Dead, ## in an active game, but dead
	Inactive ## not being used, such as in the menu
};
var player_state = State.Inactive; # starting in menu

@onready var player_data = {
	"radius": $sphere.radius,
	"spawn": Global.player_spawn_points[0], # changed later by multiplayer.gd
	"position": Global.player_spawn_points[0], # changed by input if host, multiplayer.gd if peer
	"forward": Vector3.RIGHT, # TODO: probably want diff for diff spawns?
	"current_height": 0.0,
	"jumping": false,
	"ready": false,
};

@export var player_movement = {
	"rotation_speed": 0.5,
	"turn_speed": 1.5,
	"jump_height": 0.15,
	"jump_time": {
		"up": 1.0,
		"down": 1.0,
	},
}

var jump_tween = null;

func _ready() -> void:
	$timer.connect("timeout", start_game);
	Signals.round_reset.connect(reset);
	Signals.players_ready.connect(start_countdown);
	face_forward();

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_refresh") and OS.is_debug_build():
		reset();
	if Global.state != Global.State.Game or self.player_type == Type.Peer:
		return;
	if self.player_state == State.Playing:
		move_and_look(delta);

func move_and_look(delta: float) -> void:
	var world_intersection = (global_position - Global.world["position"]).normalized();
	if Input.is_action_pressed("turn_right"):
		self.player_data["forward"] *= Quaternion(world_intersection, self.player_movement["turn_speed"] * delta);
	if Input.is_action_pressed("turn_left"):
		self.player_data["forward"] *= Quaternion(world_intersection, self.player_movement["turn_speed"] * delta * -1.0);
	if Input.is_action_just_pressed("jump"):
		jump();
	var forward_rotation = Quaternion(self.player_data["forward"], self.player_movement["rotation_speed"] * delta)
	self.player_data["position"] *= forward_rotation;
	var player_origin = self.player_data["position"] * (1.0 + self.player_data["current_height"]);
	transform.origin = player_origin;
	look_at(forward_rotation * player_origin);

func start_game() -> void:
	print("start game");
	self.player_state = State.Playing;
	if self.player_type == Type.Host:
		self.player_data["ready"] = false;
	
func jump() -> void:
	if self.player_data["jumping"]:
		return;
	self.player_data["jumping"] = true;
	self.jump_tween = get_tree().create_tween();
	self.jump_tween.tween_property(self, "player_data:current_height", self.player_movement["jump_height"], self.player_movement["jump_time"]["up"]);
	var jump_down = func():
		self.jump_tween = get_tree().create_tween();
		self.jump_tween.tween_property(self, "player_data:current_height", 0.0, self.player_movement["jump_time"]["down"]);
		var jump_finish = func():
			self.player_data["jumping"] = false;
		self.jump_tween.tween_callback(jump_finish);
	self.jump_tween.tween_callback(jump_down);

func die() -> void:
	if self.player_state == State.Playing:
		self.player_state = State.Dead; # TODO: some death animation

func reset() -> void:
	# TODO: on initial join, player_spawn set too late to apply
	if self.player_type == Type.Host: # multiplayer.gd will handle peer positioning
		self.player_data["position"] = self.player_data["spawn"];
		transform.origin = self.player_data["spawn"];
		self.player_data["forward"] = Vector3.RIGHT; # TODO: probably want diff for diff spawns?
		face_forward();
		# TODO: feel like should reset jump values, but cannot get it to work
	$trail.destroy_points();
	extra_trail_clear(); # TODO: this shouldn't be necessary
	self.player_state = State.Waiting;
	$timer.stop();

func face_forward() -> void:
	var p_pos = self.player_data["spawn"];
	var w_pos = Global.world["position"];
	var w_p_line = (p_pos - w_pos).normalized();
	var forward_rotation = Quaternion(Vector3.RIGHT, 0.05 * PI);
	look_at(forward_rotation * p_pos, Vector3.RIGHT);
# TODO: make more dynamic: currently not usable on _ready() or $timer.start, for example

func start_countdown() -> void:
	if $timer.is_stopped():
		$timer.start();
		
func extra_trail_clear() -> void:
	var clear_timer = Timer.new();
	clear_timer.wait_time = 3.0;
	clear_timer.one_shot = true;
	clear_timer.connect("timeout", $trail.destroy_points);
	add_child(clear_timer);
	clear_timer.start();
