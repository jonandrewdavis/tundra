# TODO: Tool? Or does it cause issues? It's not necessary.
# TODO: Occlude?
@tool 
extends Node3D

# Required nodes
@export var multiplayer_spawner: MultiplayerSpawner 
@export var platforms_container: Node3D 
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
var starting_platforms: Array[PackedScene] = [forest_1, forest_1, forest_1]
var current_platforms: Array[Node3D] = []

enum DIR { 
	BEHIND,
	INFRONT,
}

func _ready() -> void:
	if Engine.is_editor_hint():
		walking_scene_tracker = $Marker3D
		
	if not Engine.is_editor_hint():
		for scene_to_add in SCENE_LIST:
			multiplayer_spawner.add_spawnable_scene(scene_to_add.resource_path)	

	# To be server authoratative, return early if not server
	if not multiplayer.is_server():
		return
	
	if !platforms_container or starting_platforms.size() == 0:
		push_warning('No platform container or starters')
		return

	for starting_scene in starting_platforms:
		var new_platform = starting_scene.instantiate()
		platforms_container.add_child(new_platform, true)
		current_platforms.append(new_platform)

	current_platforms[0].global_position.z = -walking_scene_length
	current_platforms[2].global_position.z = walking_scene_length
	
	add_child(walking_scene_timer)
	walking_scene_timer.wait_time = 1.0
	walking_scene_timer.timeout.connect(on_check_walking_timer)
	walking_scene_timer.start()


func on_check_walking_timer():
	if !walking_scene_tracker:
		# Set tracking to Castle.
		if Hub.castle:
			walking_scene_tracker = Hub.castle
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

func add_platform(dir: DIR, scene_index = 0):
	if dir == DIR.INFRONT:
		var new_platform = SCENE_LIST[scene_index].instantiate()
		current_platforms.push_back(new_platform)
		platforms_container.add_child(new_platform, true)
		var new_offset = (walking_scene_length * 2) # TODO: Math out why this is correct.
		new_platform.global_position.z = walking_scene_center + new_offset
	else:
		var new_platform = SCENE_LIST[scene_index].instantiate()
		current_platforms.push_front(new_platform)
		platforms_container.add_child(new_platform, true)
		var new_offset = (walking_scene_length * 2) # TODO: Math out why this is correct.
		new_platform.global_position.z = walking_scene_center - new_offset	
