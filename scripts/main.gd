extends Node3D

var game_running = false;

func _ready() -> void:
	while $game == null or $menu == null:
		await get_tree().create_timer(0.1).timeout 
	show_gui();

func show_gui() -> void:
	$game.visible = false;
	$menu.visible = true;

func show_game() -> void:
	$game.visible = true;
	$menu.visible = false;
