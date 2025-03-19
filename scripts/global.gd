extends Node;

enum State {
	Menu,
	Game
};
var state = State.Menu;

var world = {
	"position": Vector3.ZERO,
	"radius": 7.5,
}; # TODO: actually apply this to the world node, somehow

var player_radius = 0.5; # TODO: probably want connected to real player instance or something

var player_spawn_points: Array[Vector3] = [
	Vector3(0, world["radius"] + (player_radius * 0.5), 0),
	Vector3(0, 0, world["radius"] + (player_radius * 0.5)),
	Vector3(world["radius"] + (player_radius * 0.5), 0, 0),
	Vector3(0, -1.0 * (world["radius"] + (player_radius * 0.5)), 0),
	Vector3(0, 0, -1.0 * (world["radius"] + (player_radius * 0.5))),
	Vector3(-1.0 * (world["radius"] + (player_radius * 0.5)), 0, 0)
];
# TODO: many more player_spawns, real ordering
# TODO: use world["position"]
# TODO: I don't love this being here, in general
