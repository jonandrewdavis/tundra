extends Node

var world: Node3D


# The castle speed needs a MultiplayerSyncronizer, so anyone
# who joins gets the latest value. We could also do an RPC
# on joining, but this might work.
func _ready() -> void:
	pass
	
	
