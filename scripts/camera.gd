extends Camera3D

@export var player: Node3D;
@export var distance: float = 5.0;

func _process(delta: float) -> void:
	var p_pos = player.global_position;
	var w_pos = Vector3.ZERO;
	var w_p_line = (p_pos - w_pos).normalized();
	position = p_pos + w_p_line * distance;
	
	look_at(p_pos, player.forward_vec * Quaternion(w_p_line, 1.5 * PI));
