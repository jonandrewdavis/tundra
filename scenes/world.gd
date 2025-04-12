extends Node3D

@export var castle_speed: float = 0.0

const gun_drone = preload("res://assets/characters/bot_drone_winter/GunDrone.tscn")

@onready var world_env: WorldEnvironment = $Env/WorldEnvironment
@export var fog: bool = false:
	set(val):
		if world_env:
			world_env.environment.volumetric_fog_enabled = val
			notify_property_list_changed()
	get():
		return world_env.environment.volumetric_fog_enabled

func _ready():
	Hub.world = self

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("DEBUG_L"):
		fog = !fog

@rpc('any_peer')
func change_castle_speed(new_speed):
	if multiplayer.is_server():
		castle_speed = new_speed

@rpc("call_local")
func spawn_enemy():
	var new_drone = gun_drone.instantiate()
	$EnemiesContainer.add_child(new_drone, true)
	new_drone.global_position = Vector3(10.0, 15.0, 10.0)
