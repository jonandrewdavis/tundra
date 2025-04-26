extends AnimatableBody3D
class_name MovingCastle

# TODO: skip hub
@export var castle_speed: float = 1.2
@export var castle_on: bool = false

# TODO: Allow picking new targets on a map or something
# TODO: Rotation, stop at crossroads
@onready var castle_target: Vector3 = Vector3(0.0, 1.0, 10000.0)

# Internal 
@onready var _origin: Vector3 = global_position
@onready var _distance: float = _origin.distance_to(castle_target)
var _velocity: Vector3 = Vector3.ZERO

func _ready():
	Hub.castle = self

	NetworkRollback.before_loop.connect(_save_previous)
	NetworkRollback.on_prepare_tick.connect(_apply_tick)

	sync_to_physics = false

	if multiplayer.is_server():
		Hub.change_castle_speed.connect(_on_change_castle_speed)

func get_velocity() -> Vector3:
	return _velocity

var prev: Vector3

func _save_previous():
	prev = global_position

func _apply_tick(tick: int):
	if castle_on:
		#var previous_position = global_position
		translate(Vector3(0.0, 0.0, -0.02))
		_velocity = (global_position - prev) / NetworkTime.ticktime * 2
	else:
		_velocity = Vector3.ZERO

func _get_position_for_tick(_tick: int):
	#var distance_moved = NetworkTime.ticks_to_seconds(tick) * castle_speed
	#var progress = distance_moved / _distance
	#return _origin.lerp(castle_target, progress)
	return global_position
		
func _on_change_castle_speed():
	castle_on = !castle_on
