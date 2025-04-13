extends Node

var world
var player_container

# NOTE: Signals do not allow typed params. Even the docs say "you're on your own"...
signal player_added #network_id	
signal change_castle_speed #speed

var castle_speed = 0.0

func _ready() -> void:
	player_added.connect(on_player_added_hub)
	change_castle_speed.connect(on_change_castle_speed)
	pass	

func get_player(network_id: int):
	var players = world.get_node('PlayerContainer').get_children()
	for player in players:
		if player.is_in_group('players') && str(player.name) == str(network_id):
			return player

# TODO: Scoreboard
func on_player_added_hub(_network_id):
	pass

func on_change_castle_speed(new_speed):
	castle_speed = new_speed
