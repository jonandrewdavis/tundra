extends Node3D

@export var move_speed: float = 0.0
@export var turn_speed: float = 1.0

#TODO: this would function better as Animatable Platform 3D or whatever
# this means we'd have to bake our collison mesh and add it

func _ready() -> void:
	if not multiplayer.is_server():
		set_process(false)
		return

	Hub.change_castle_speed.connect(on_change_castle_speed)

func _process(delta: float) -> void:
	_handle_movement(delta)

func _handle_movement(delta):
	#var dir = Input.get_axis('ui_down', 'ui_up')
	# Constantly moves "forward" (-1.0)
	translate(Vector3(0, 0, -1.0) * move_speed * delta)

func on_change_castle_speed(new_speed):
	move_speed = new_speed
