class_name Game extends Node2D

@export var player_scene: PackedScene
@export var spawn_locations_group: Node

var players_by_player_id = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for spawn_location in spawn_locations_group.get_children():
		spawn_location.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_phone_motion(player_id, motion):
	var player = players_by_player_id[player_id]
	if (player):
		var dir = Vector2(motion["acc"]["x"], motion["acc"]["y"])
		print(dir, Time.get_ticks_msec())
		player.jump(dir)

func player_joined(player_id):
	var player = player_scene.instantiate();
	var spawn_locations = spawn_locations_group.get_children()
	print(spawn_locations)
	print(spawn_locations.size)
	var spawn_idx = randi_range(0, spawn_locations.size()-1)
	player.position = spawn_locations[spawn_idx].position;
	add_child(player)
	players_by_player_id[player_id] = player
