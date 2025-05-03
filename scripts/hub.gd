extends Node

# NOTICE: Needs to be hardcoded, since the server is headless & uses Hub.viewport to cast rays from the "camera"
var viewport = Vector2i(1152, 648)

var world: Node3D
var player_container: Node3D
var castle: MovingCastle 

var projectile_system: ProjectileSystem # Sets self on ready
var enemy_system: EnemySystem # Sets self on ready

# NOTE: Signals do not allow typed params. Even the docs say "you're on your own"...
signal player_added #network_id: int

func _ready() -> void:
	# Can copy paste these into other files to listen to signals (also removes unused warning):
	player_added.connect(on_player_added_hub)

func get_player(network_id: int):
	var players = world.get_node('PlayerContainer').get_children()
	for player in players:
		if player.is_in_group('players') && str(player.name) == str(network_id):
			return player

# TODO: Scoreboard
func on_player_added_hub(_network_id):
	pass
