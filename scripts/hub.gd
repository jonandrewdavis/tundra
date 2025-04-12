extends Node

var world
var player_container

# arg: player
signal player_added

# The castle speed needs a MultiplayerSyncronizer, so anyone
# who joins gets the latest value. We could also do an RPC
# on joining, but this might work.
func _ready() -> void:
	print('WORLD PLS', world)
	pass	

func get_player(id):
	print('WORLD', world)
	var players = world.get_node('PlayerContainer').get_children()
	for player in players:
		print('p', player.id, id)
		if str(player.id) == str(id):
			return player
