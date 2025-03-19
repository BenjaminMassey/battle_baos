extends Button

@export var player: Player;

func _ready() -> void:
	var enable = func():
		disabled = false;
		show();
	Signals.round_reset.connect(enable);
	Signals.players_ready.connect(hide);

func _pressed() -> void:
	disabled = true;
	player.player_data["ready"] = true;
