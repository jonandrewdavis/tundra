extends Node

var world
var player_container

signal player_added

func _ready() -> void:
	player_added.connect(on_player_added_hub)
	pass	

func get_player(network_id: int):
	var players = world.get_node('PlayerContainer').get_children()
	for player in players:
		if player.is_in_group('players') && str(player.name) == str(network_id):
			return player

# TODO: Scoreboard
func on_player_added_hub(_network_id):
	pass
