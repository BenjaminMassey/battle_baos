extends Node3D

@export var move_speed: float = 1.0;
@export var turn_speed: float = 5.0;

var radius: float = 8; # world radius + player radius
var inclination: float = 0;
var azimuth: float = 0;
var direction: float = 0;

func _process(delta):
	if Input.is_action_pressed("rotate_left"):
		direction -= turn_speed * delta;
	if Input.is_action_pressed("rotate_right"):
		direction += turn_speed * delta;
		
	azimuth += move_speed * cos(direction) * delta;
	inclination += move_speed * sin(direction) * delta;
	
	azimuth = fmod(azimuth, 2.0 * PI);
	inclination = clamp(inclination, 0, PI)
	
	var x: float = radius * sin(inclination) * cos(azimuth);
	var y: float = radius * sin(inclination) * sin(azimuth);
	var z: float = radius * cos(inclination);
	var new_position := Vector3(x, y, z);
	
	if position != new_position:
		look_at(new_position, Vector3.UP);
		
	position = new_position;
