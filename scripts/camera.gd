extends Camera3D

@export var player: Node3D;

func _process(delta: float) -> void:
	rotation = player.rotation;
	look_at(player.global_position);
