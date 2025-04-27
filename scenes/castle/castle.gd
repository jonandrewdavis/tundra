extends AnimatableBody3D
class_name MovingCastle

# TODO: skip hub
@export var castle_speed: float = 1.2
@export var castle_on: bool = false

# TODO: Allow picking new targets on a map or something
# TODO: Rotation, stop at crossroads
#@onready var castle_target: Vector3 = Vector3(0.0, 1.0, 10000.0)

# Internal 
#@onready var _origin: Vector3 = global_position
#@onready var _distance: float = _origin.distance_to(castle_target)
var _velocity: Vector3 = Vector3.ZERO

func _ready():
	Hub.castle = self

	NetworkTime.before_tick.connect(_save_previous_position)
	NetworkTime.on_tick.connect(_apply_tick)
	NetworkTime.after_tick.connect(_calc_velocity)

	sync_to_physics = false

	# Player Bones
	set_collision_layer_value(4, true)
	set_collision_mask_value(4, true)
	
	if multiplayer.is_server():
		Hub.change_castle_speed.connect(_on_change_castle_speed)

func get_velocity() -> Vector3:
	return _velocity

var prev: Vector3

func _save_previous_position(_delta: float, _tick: int):
	prev = global_position

func _apply_tick(_delta: float, _tick: int):
	if castle_on:
		translate(Vector3(0.0, 0.0, -0.05))

func _calc_velocity(_delta: float, _tick: int):
	_velocity = (global_position - prev) / NetworkTime.ticktime
	
	
func _on_change_castle_speed():
	castle_on = !castle_on
