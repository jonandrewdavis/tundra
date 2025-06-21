extends Node

signal update_objective

# NOTICE: Needs to be hardcoded, since the server is headless & uses Hub.viewport to cast rays from the "camera"
var viewport = Vector2i(1152, 648)

var world: Node3D
var player_container: Node3D
var castle: MovingCastle 

var resource_system: ResourceSystem
var projectile_system: ProjectileSystem # Sets self on ready
var enemy_system: EnemySystem # Sets self on ready

var objectives_collected: int = 0

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

func on_objective_collected():
	objectives_collected = objectives_collected + 1
	if objectives_collected == 5:
		castle.gain_fuel(1000)
		castle.health_system.heal(2000)
		await get_tree().create_timer(5).timeout
		objectives_collected = 0
		update_objective.emit(0)
		return

	update_objective.emit(objectives_collected)
