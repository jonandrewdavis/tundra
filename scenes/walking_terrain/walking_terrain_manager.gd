# TODO: Tool? or does it cause issues.
# @tool
extends Node3D



var walking_scene = preload("res://scenes/walking_terrain/walking_snow.tscn")
var walking_scene_length = 200.0

var platforms_container: Node3D

var current_platforms = []

# TODO: label these groups, export tracker, so parent can set it, otherwise Marker3D here
var walking_scene_timer = Timer.new()
var walking_scene_tracker: Node3D
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

func on_player_added(player):
	walking_scene_tracker = player


func on_check_walking_timer():
	if !walking_scene_tracker:
		push_warning('No walking_scene_tracker to check')
		return
		
	if walking_scene_tracker.global_position.z > walking_scene_center + walking_scene_length:
		var new_platform = walking_scene.instantiate()
		# placing in front (half left to go)
		new_platform.global_position.z = walking_scene_center + walking_scene_length / 2
		current_platforms.append(new_platform)
		current_platforms.pop_front()
		# Forward progress has been made, set the new center.
		walking_scene_center = walking_scene_center + walking_scene_length
		
		
	if walking_scene_tracker.global_position.z < walking_scene_center - walking_scene_length:
		print('You tried to go backwards, were almost ready for that.')
		pass
		#
		
# TODO: backwards? eh. maybe.
	# us absolute dist?
	# could measure to location of (transform.origin) to find the center of the current thingy
	# that way you could support variable "length" scene in the future
	# you'd have to measure each incoming scene to figure how where / how to place them.
