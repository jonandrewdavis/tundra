extends AnimatableBody3D
class_name MovingPlatform

@export var speed: float = 2.
#var _velocity: Vector3 = Vector3.ZERO


func _ready():
	NetworkRollback.on_prepare_tick.connect(_apply_tick)

func _apply_tick(tick: int):
	pass
	#var previous_position = _get_position_for_tick(tick - 1)
	#global_position = _get_position_for_tick(tick)
	
	#constant_linear_velocity = Vector3(0.0, 0.0, 0.1) / NetworkTime.ticktime
#
#func _get_position_for_tick(tick: int):
	#var distance_moved = NetworkTime.ticks_to_seconds(tick) * speed
	#var progress = distance_moved / _distance
	#progress = pingpong(progress, 1)
	#
	#return _origin.lerp(_target, progress)
