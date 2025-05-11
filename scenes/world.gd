@tool
extends Node3D

@onready var world_env: WorldEnvironment =  $Environment_V2/WorldEnvironment


# Editor debug fog
@export var fog: bool = true:
	set(val):
		if world_env:
			world_env.environment.volumetric_fog_enabled = val
			notify_property_list_changed()
	get():
		return world_env.environment.volumetric_fog_enabled

func _ready():
	if not Engine.is_editor_hint():
		Hub.world = self
		if multiplayer.is_server():
			NetworkManager.hide_loading()

	if not multiplayer.is_server():
		return
		

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("DEBUG_L"):
		fog = !fog
