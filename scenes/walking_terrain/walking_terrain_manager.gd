# TODO: Tool? Or does it cause issues? It's not necessary.
# TODO: Occlude?
# TODO: spawner ain't gonna work with tool.
#@tool 
extends Node

# Required nodes
@export var spawner: MultiplayerSpawner 
@export var container: Node3D
var walking_scene_tracker
var walking_scene_timer = Timer.new()

# CRITICAL: 
# Walking Scenes with ProtonScatter must: 
# - show_output_in_tree = true
# - render_mode = "Create Copies"
# - keep_static_colliders = true
# - force_rebuild_on_load = false

# Server's Headless mode DOES NOT work well with instances & rebuild. 
# Presumably due to lack of GPU

# CRITICAL: Walking platforms must have a MultiplayerSync with position
# TODO: Use a custom spawn function to set it!!
var start = preload("res://scenes/walking_terrain/walking_scenes/starting_area.tscn")
var forest_1 = preload("res://scenes/walking_terrain/walking_scenes/forest_1.tscn")

var SCENE_LIST = [start, forest_1]

var walking_scene_length = 200.0
var walking_scene_center = 0.0

# 0 = "most behind"
# 1 = "center"
# 2 = "coming soon!"
#var starting_platforms: Array[PackedScene] = [forest_1, start, forest_1]

var current_platforms: Array[Node3D] = []

enum DIR { 
	BEHIND,
	INFRONT,
}

func _ready() -> void:
	spawner.set_spawn_function(handle_platform_spawn)
	#for scene_to_add in SCENE_LIST:
		#spawner.add_spawnable_scene(scene_to_add.resource_path)	

	add_child(walking_scene_timer)
	walking_scene_timer.wait_time = 1.0
	walking_scene_timer.timeout.connect(on_check_walking_timer)
	walking_scene_timer.start()	
	
	await get_tree().create_timer(2.0).timeout
	set_up_initial_platforms()


func set_up_initial_platforms():
	var behind = spawner.spawn([0, -walking_scene_length])
	var current = spawner.spawn([0, 0])
	var front = spawner.spawn([0, walking_scene_length])
	
	current_platforms.append(behind)
	current_platforms.append(current)
	current_platforms.append(front)


func on_check_walking_timer():
	if !walking_scene_tracker:
		# Set tracking to Castle.
		if Hub.castle:
			walking_scene_tracker = Hub.castle
		return
	
	if current_platforms.size() != 3 || container.get_child_count() != 3:
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

# TODO: Abstract this better.
func add_platform(dir: DIR, _scene_index = 0):
	if dir == DIR.INFRONT:
		var new_offset = (walking_scene_length * 2) # TODO: Math out why this is correct.
		var new_platform = 	spawner.spawn([0, walking_scene_center + new_offset])
		current_platforms.push_back(new_platform)
	else:
		var new_offset = (walking_scene_length * 2) # TODO: Math out why this is correct.
		var new_platform = spawner.spawn([0, walking_scene_center - new_offset])
		current_platforms.push_front(new_platform)

# [index, pos]
func handle_platform_spawn(data: Variant): 
	var scene_index = data[0]
	var platform_pos = data[1]
	var new_platform = SCENE_LIST[scene_index].instantiate()
	new_platform.position.z = platform_pos

	return new_platform
