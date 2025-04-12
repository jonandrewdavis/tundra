extends Node

var world
var player_container

# TODO: Can't type signal args???
# arg: network_id: int
signal player_added

# The castle speed needs a MultiplayerSyncronizer, so anyone
# who joins gets the latest value. We could also do an RPC
# on joining, but this might work.
func _ready() -> void:
	print('WORLD PLS', world)
	pass	

func get_player(network_id: int):
	print('WORLD', network_id)
	var players = world.get_node('PlayerContainer').get_children()
	for player in players:
		if player.is_in_group('players') && str(player.name) == str(network_id):
			return player
