extends AnimatableBody3D
class_name MovingCastle

@export var speed: float = 0.0

# TODO: Allow picking new targets on a map or something
# TODO: Rotation, stop at crossroads
@onready var castle_target: Vector3 = Vector3(0.0, 1.0, 10000.0)


# Internal 
@onready var _origin: Vector3 = global_position
@onready var _distance: float = _origin.distance_to(castle_target)
var _velocity: Vector3 = Vector3.ZERO

func get_velocity() -> Vector3:
	return _velocity

func _ready():
	NetworkRollback.on_prepare_tick.connect(_apply_tick)
	sync_to_physics = false

func _apply_tick(tick: int):
	var previous_position = _get_position_for_tick(tick - 1)
	global_position = _get_position_for_tick(tick)
	
	_velocity = (global_position - previous_position) / NetworkTime.ticktime

func _get_position_for_tick(tick: int):
	var distance_moved = NetworkTime.ticks_to_seconds(tick) * speed
	var progress = distance_moved / _distance
	return _origin.lerp(castle_target, progress)
