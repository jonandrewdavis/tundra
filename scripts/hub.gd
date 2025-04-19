extends Node

const gun_drone = preload("res://assets/characters/bot_drone_winter/GunDrone.tscn")

var world: Node3D
var player_container: Node3D
var heat_dome: Node3D

# NOTE: Signals do not allow typed params. Even the docs say "you're on your own"...
signal player_added #network_id: int
signal change_castle_speed #speed: int
signal heat_dome_value #value: int

var castle_speed = 0.0

func _ready() -> void:
	# Can copy paste these into other files to listen to signals (also removes unused warning):
	player_added.connect(on_player_added_hub)
	change_castle_speed.connect(on_change_castle_speed)
	heat_dome_value.connect(on_change_heat_dome_value)
	pass

func get_player(network_id: int):
	var players = world.get_node('PlayerContainer').get_children()
	for player in players:
		if player.is_in_group('players') && str(player.name) == str(network_id):
			return player

# TODO: Scoreboard
func on_player_added_hub(_network_id):
	pass

func on_change_castle_speed(new_speed: int):
	push_warning('Called castle speed on hub', castle_speed)
	castle_speed = new_speed

func on_change_heat_dome_value(_value: int):
	pass
	
func debug_create_enemy():
	var container = world.get_node('EnemiesContainer')
	var new_drone = gun_drone.instantiate()
	container.add_child(new_drone, true)
	var rand = randi_range(0, 3)
	new_drone.global_position = Vector3(0.0 + rand, 8.0, -35.0 + rand)
