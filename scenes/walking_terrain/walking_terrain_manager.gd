# TODO: Tool? or does it cause issues.
@tool
extends Node3D

# Required nodes
@export var multiplayer_spawner: MultiplayerSpawner 
@export var platforms_container: Node3D 
var walking_scene_tracker
var walking_scene_timer = Timer.new()

var walking_scene = preload("res://scenes/walking_terrain/walking_snow.tscn")
var walking_scene_length = 200.0
var walking_scene_center = 0.0

# We track current_platforms in an array because adding & removing nodes can change order.
var current_platforms = []

enum DIR { 
	BEHIND,
	INFRONT,
}

func _ready() -> void:
	multiplayer_spawner.add_spawnable_scene(walking_scene.resource_path)	
	
	# To be server authoratative, return early if not server
	if not multiplayer.is_server():
		return

	if !platforms_container:
		push_warning('No platform container')
		return
	if !walking_scene:
		push_warning('No walking scene')	
	
	
	add_child(walking_scene_timer)
	walking_scene_timer.wait_time = 1.0
	walking_scene_timer.timeout.connect(on_check_walking_timer)
	walking_scene_timer.start()
	
	if Engine.is_editor_hint():
		walking_scene_tracker = $Marker3D
	else:	
		Hub.player_added.connect(on_player_added)

	# Similar to [0, 1, 2] but does not allocate an array.
	# 0 = "most behind"
	# 1 = "center"
	# 2 = "coming soon!"
	# TODO: This could be generic & just called to make any scene walk based on a relative pos 0.0, 100.0
	for i in range(3):
		var new_platform = walking_scene.instantiate()
		platforms_container.add_child(new_platform, true)
		current_platforms.append(new_platform)

	current_platforms[0].global_position.z = -walking_scene_length
	current_platforms[2].global_position.z = walking_scene_length

func on_player_added(player: int):
	walking_scene_tracker = Hub.get_player(player)


func on_check_walking_timer():
	if !walking_scene_tracker:
		push_warning('No walking_scene_tracker to check')
		return
	
	if current_platforms.size() != 3 || platforms_container.get_child_count() != 3:
		push_warning('Incorrect number of platforms')
		return
		
		
	#print('DEBUG: walking_scene_tracker Z: ', walking_scene_tracker.global_position.z)

	if walking_scene_tracker.global_position.z > walking_scene_center + walking_scene_length:
		remove_platform(DIR.BEHIND)
		add_platform(DIR.INFRONT)
		walking_scene_center = walking_scene_center + walking_scene_length

	if walking_scene_tracker.global_position.z < walking_scene_center - walking_scene_length:
		remove_platform(DIR.INFRONT)
		add_platform(DIR.BEHIND)
		walking_scene_center = walking_scene_center - walking_scene_length


func remove_platform(dir: DIR):
	if dir == DIR.BEHIND:
		current_platforms[0].queue_free()
		current_platforms.pop_at(0)
	else:
		current_platforms[2].queue_free()
		current_platforms.pop_at(2)

func add_platform(dir: DIR):
	if dir == DIR.INFRONT:
		var new_platform = walking_scene.instantiate()
		current_platforms.push_back(new_platform)
		platforms_container.add_child(new_platform, true)
		var new_offset = (walking_scene_length * 2) # TODO: Math out why this is correct.
		new_platform.global_position.z = walking_scene_center + new_offset
	else:
		var new_platform = walking_scene.instantiate()
		current_platforms.push_front(new_platform)
		platforms_container.add_child(new_platform, true)
		var new_offset = (walking_scene_length * 2) # TODO: Math out why this is correct.
		new_platform.global_position.z = walking_scene_center - new_offset	
