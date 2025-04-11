extends Node3D

# TODO: preload

# z = 200
var walking_scene = preload("res://scenes/walking_terrain/walking_snow.tscn")

var current_platforms = []

func _ready() -> void:
	for i in 3: 
		var new_platform = walking_scene.instantiate()
		current_platforms.push_back(walking_scene)

	#var pos = 
	#for node in current_platforms:
		
		

func _process(delta: float) -> void:
	pass
