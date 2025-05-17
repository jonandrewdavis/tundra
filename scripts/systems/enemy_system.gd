extends Node
class_name EnemySystem

const gun_drone_scene = preload("res://scenes/enemies/gun_drone/GunDrone.tscn")
const dog_enemy_scene = preload("res://scenes/enemies/dog/dog_enemy.tscn")
const bug_1_enemy_scene = preload("res://scenes/enemies/bug_1/bug_1.tscn")
const bot_1_enemy_scene = preload("res://scenes/enemies/bot_1/bot_1_enemy.tscn")

@onready var spawner: MultiplayerSpawner= $MultiplayerSpawner
@onready var container: Node3D = $EnemyContainer

signal spawn_drone
signal spawn_dog
signal spawn_bug_1
signal spawn_bot_1
signal debug_kill_all

enum EnemyType { DRONE, DOG, BUG_1, BOT_1 }

var timer_adjust_heat: Timer = Timer.new()

var timer_spawn_patrol_rate: float = 60.0
var timer_spawn_patrol: Timer = Timer.new()

var enemy_max := 80
var wave_number := 0

var patrol_list = []


# TODO: Patrols shoudl includce bigger version
# TODO: Spawn function should allow 2x big version with more health & attack
# TODO: Every 1 sec add 1 heat. 
# Reach 180 heat & a patrol spawns
# Heat sets to 0.
# When a new player joins, raises the multiplier
# Player multiple factor should be 1.7 and round up? or round down? on the # of enemies to spawn




# TODO: For each type, set up all the binds, adds, and the create func better
# TOO MUCH REPETITION

# TODO: Timers
func _ready() -> void:
	Hub.enemy_system = self

	spawner.set_spawn_function(create_enemy)

	spawner.add_spawnable_scene(gun_drone_scene.resource_path)
	spawner.add_spawnable_scene(dog_enemy_scene.resource_path)
	spawner.add_spawnable_scene(bug_1_enemy_scene.resource_path)
	spawner.add_spawnable_scene(bot_1_enemy_scene.resource_path)
	
	if not multiplayer.is_server():
		return
	
	spawn_drone.connect(debug_create_enemy.bind(EnemyType.DRONE))
	spawn_dog.connect(debug_create_enemy.bind(EnemyType.DOG))
	spawn_bug_1.connect(debug_create_enemy.bind(EnemyType.BUG_1))
	spawn_bot_1.connect(debug_create_enemy.bind(EnemyType.BOT_1))
	
	debug_kill_all.connect(on_debug_kill_all)

	add_child(timer_spawn_patrol)
	timer_spawn_patrol.start(timer_spawn_patrol_rate)
	timer_spawn_patrol.timeout.connect(spawn_new_patrol)
	
	patrol_list = prepare_possible_patrols()
	
# TODO: Could use a custom spawn function?
# TODO: enemy "pool" to spawn fewer objects
func debug_create_enemy(type: EnemyType):
	var enemy_to_spawn
	
	match type:
		EnemyType.DRONE:
			enemy_to_spawn = gun_drone_scene.instantiate()
		EnemyType.DOG:
			enemy_to_spawn = dog_enemy_scene.instantiate()
		EnemyType.BUG_1:
			enemy_to_spawn = bug_1_enemy_scene.instantiate()
		EnemyType.BOT_1:
			enemy_to_spawn = bot_1_enemy_scene.instantiate()

	enemy_to_spawn.position = Hub.castle.global_position + Vector3(randi_range(-3, 3), 0.8, randi_range(-3, 3)) * 10
	container.add_child(enemy_to_spawn, true)
	#var rand = randi_range(0, 3)

# TODO: Stronger typing
func create_enemy(data: Variant):
	var type = data
	var enemy_to_spawn
	
	match type:
		EnemyType.DRONE:
			enemy_to_spawn = gun_drone_scene.instantiate()
		EnemyType.DOG:
			enemy_to_spawn = dog_enemy_scene.instantiate()
		EnemyType.BUG_1:
			enemy_to_spawn = bug_1_enemy_scene.instantiate()
		EnemyType.BOT_1:
			enemy_to_spawn = bot_1_enemy_scene.instantiate()

	enemy_to_spawn.position = Hub.castle.global_position + Vector3(0.0, 0.0, -130.0) + Vector3(randi_range(-3, 3), 0.2, randi_range(-3, 3)) * 10
	#container.call_deferred("add_child", enemy_to_spawn, true)
	return enemy_to_spawn

func get_player_factor():
	return Hub.player_container.get_child_count() * 2

func prepare_possible_patrols():
	const first_patrol = [EnemyType.DRONE, EnemyType.DRONE, EnemyType.DRONE]
	const second_patrol = [EnemyType.DOG, EnemyType.DOG, EnemyType.DOG,EnemyType.DOG]
	const third_patrol = [EnemyType.BUG_1, EnemyType.BUG_1, EnemyType.BUG_1,EnemyType.BUG_1, EnemyType.BUG_1]

	return [first_patrol, second_patrol, third_patrol]

func spawn_new_patrol():
	if container.get_child_count() >= enemy_max or get_player_factor() == 0:
		return
	
	for n in range(get_player_factor()):
		# Bugs
		for enemy_in_wave in patrol_list[wave_number]:
			spawner.spawn(enemy_in_wave)

	wave_number = wave_number + 1
	if wave_number > patrol_list.size():
		wave_number = 0

func cleanup_out_of_bounds() -> void:
	if container.get_child_count() == 0:
		return
		
	for enemy in container.get_children():
		if enemy.global_position.distance_to(Hub.castle.global_position) > 300.0:
			enemy.set_process(false)
			queue_free()
		
	if get_player_factor() == 0:
		on_debug_kill_all()

func on_debug_kill_all():
	for enemy in container.get_children():
		enemy.set_process(false)
		enemy.queue_free()
	
