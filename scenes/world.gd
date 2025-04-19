@tool
extends Node3D

@export var castle_speed: float = 0.0

@onready var world_env: WorldEnvironment = $Env/WorldEnvironment

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

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("DEBUG_L"):
		fog = !fog
