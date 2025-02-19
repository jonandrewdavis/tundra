@tool
extends Node3D

@onready var world_env: WorldEnvironment = $Env/WorldEnvironment
@export var fog: bool = false:
	set(val):
		if world_env:
			world_env.environment.volumetric_fog_enabled = val
			notify_property_list_changed()
	get():
		return world_env.environment.volumetric_fog_enabled


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("DEBUG_L"):
		fog = !fog
