# TODO: Tool? or does it cause issues.
@tool
extends Node3D


var walking_scene = preload("res://scenes/walking_terrain/walking_snow.tscn")
var walking_scene_length = 200.0

var platforms_container: Node3D

# We track current_platforms in an array because adding & removing nodes can change order.
var current_platforms = []

# TODO: label these groups, export tracker, so parent can set it, otherwise Marker3D here
var walking_scene_timer = Timer.new()
@onready var walking_scene_tracker: Node3D = $Marker3D
# TODO: connect signals for platforms to remove themselves, (connect them as added)
# connect signals for baking

var walking_scene_center = 0.0

func _ready() -> void:
	platforms_container = $PlatformsContainer
	if !platforms_container:
		push_warning('No platform container')
		return
	if !walking_scene:
		push_warning('No walking scene')
	
	add_child(walking_scene_timer)
	walking_scene_timer.wait_time = 1.0
	walking_scene_timer.timeout.connect(on_check_walking_timer)
	walking_scene_timer.start()
	#
	#if Hub.has_signal('player_added'):
		#Hub.player_added.connect(on_player_added)
	
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

	# TODO: Function this.
	if walking_scene_tracker.global_position.z > walking_scene_center + walking_scene_length:
		remove_platform(DIR.BEHIND)
		add_platform(DIR.INFRONT)
		walking_scene_center = walking_scene_center + walking_scene_length

	if walking_scene_tracker.global_position.z < walking_scene_center - walking_scene_length:
		var new_platform = walking_scene.instantiate()
		platforms_container.add_child(new_platform)
		var new_offset = (walking_scene_length * 2)
		new_platform.global_position.z = walking_scene_center - new_offset
		current_platforms.prepend(new_platform)
		# Backwards progress has been made, set the new center.
		walking_scene_center = walking_scene_center + walking_scene_length

enum DIR { 
	BEHIND,
	INFRONT,
}

func remove_platform(dir: DIR):

	if dir == DIR.BEHIND:
		current_platforms[0].queue_free()
	else:
		current_platforms[2].get_children()[2].queue_free()

func add_platform(dir: DIR):
	if dir == DIR.INFRONT:
		var new_platform = walking_scene.instantiate()
		current_platforms.append(new_platform)
		platforms_container.add_child(new_platform)
		var new_offset = (walking_scene_length * 2) # TODO: Math out why this is correct.
		new_platform.global_position.z = walking_scene_center + new_offset
	else:
		platforms_container.get_children()[2].queue_free()
	

# TODO: backwards? eh. maybe.
	# us absolute dist?
	# could measure to location of (transform.origin) to find the center of the current thingy
	# that way you could support variable "length" scene in the future
	# you'd have to measure each incoming scene to figure how where / how to place them.
