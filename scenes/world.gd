@tool
extends Node3D

@export var world_env: WorldEnvironment

# Editor debug fog
@export var fog: bool = true

func _ready():
	if not Engine.is_editor_hint():
		if not world_env:
			Nodash.error_missing(world_env, 'World_Env')
			return 
			
		Hub.world = self
		Hub.player_container = $PlayerContainer
		if multiplayer.is_server():
			NetworkManager.hide_loading()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("DEBUG_L"):
		fog = !fog
