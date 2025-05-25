@tool
extends Node3D

@onready var world_env: WorldEnvironment =  $Environment_V2/WorldEnvironment

# Editor debug fog
@export var fog: bool = true

func _ready():
	if not Engine.is_editor_hint():
		Hub.world = self
		Hub.player_container = $PlayerContainer
		if multiplayer.is_server():
			NetworkManager.hide_loading()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("DEBUG_L"):
		fog = !fog
