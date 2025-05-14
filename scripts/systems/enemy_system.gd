extends Node
class_name EnemySystem

const gun_drone_scene = preload("res://scenes/enemies/gun_drone/GunDrone.tscn")
const dog_enemy_scene = preload("res://scenes/enemies/dog/dog_enemy.tscn")

@onready var spawner: MultiplayerSpawner= $MultiplayerSpawner
@onready var container: Node3D = $EnemyContainer

signal spawn_drone
signal spawn_dog

enum EnemyType { DRONE, DOG }

var spawn_timer_rate: float = 180.0
var spawn_timer: Timer = Timer.new()

var enemy_max = 50



# TODO: Patrol Resource, wave. Etc.



# TODO: Timers
func _ready() -> void:
	Hub.enemy_system = self
	
	spawn_drone.connect(debug_create_enemy.bind(EnemyType.DRONE))
	spawn_dog.connect(debug_create_enemy.bind(EnemyType.DOG))
	
	spawner.add_spawnable_scene(gun_drone_scene.resource_path)
	spawner.add_spawnable_scene(dog_enemy_scene.resource_path)
	
	add_child(spawn_timer)
	spawn_timer.start(spawn_timer_rate)
	spawn_timer.timeout.connect(spawn_new_patrol)
	
# TODO: Could use a custom spawn function?
# TODO: enemy "pool" to spawn fewer objects
func debug_create_enemy(type: EnemyType):
	var enemy_to_spawn
	
	match type:
		EnemyType.DRONE:
			enemy_to_spawn = gun_drone_scene.instantiate()
		EnemyType.DOG:
			enemy_to_spawn = dog_enemy_scene.instantiate()

	container.add_child(enemy_to_spawn, true)
	#var rand = randi_range(0, 3)
	enemy_to_spawn.global_position = Hub.castle.global_position + Vector3(randi_range(-3, 3), 0.8, randi_range(-3, 3)) * 10


func create_enemy_in_patrol(type: EnemyType):
	var enemy_to_spawn
	
	match type:
		EnemyType.DRONE:
			enemy_to_spawn = gun_drone_scene.instantiate()
		EnemyType.DOG:
			enemy_to_spawn = dog_enemy_scene.instantiate()

	container.add_child(enemy_to_spawn, true)
	enemy_to_spawn.global_position = Hub.castle.global_position + Vector3(randi_range(-3, 3), 0.8, randi_range(-3, 3)) * 10

const first_patrol = [EnemyType.DRONE, EnemyType.DRONE, EnemyType.DRONE]

const second_patrol = [EnemyType.DOG, EnemyType.DOG,]

func spawn_new_patrol():
	pass
	#for enemy in patrol:
		#create_enemy_in_patrol()

		
		
		
