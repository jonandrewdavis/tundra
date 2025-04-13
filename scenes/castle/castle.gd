extends Node3D

@export var move_speed: float = 1.2
@export var turn_speed: float = 1.0

func _ready() -> void:
	if not multiplayer.is_server():
		set_process(false)

func _process(delta: float) -> void:
	_handle_movement(delta)

func _handle_movement(delta):
	#var dir = Input.get_axis('ui_down', 'ui_up')
	# Constantly moves "forward" (-1.0)
	translate(Vector3(0, 0, -1.0) * move_speed * delta)
