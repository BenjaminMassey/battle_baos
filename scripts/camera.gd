extends Camera3D

@export var player: Player;
@export var distance: float = 5.0;

func _process(delta: float) -> void:
	if Global.state != Global.State.Game:
		return;
	var p_pos = self.player.global_position;
	var w_pos = Global.world["position"];
	var w_p_line = (p_pos - w_pos).normalized();
	self.position = p_pos + w_p_line * distance;
	
	look_at(p_pos, self.player.player_data["forward"] * Quaternion(w_p_line, 1.5 * PI));
