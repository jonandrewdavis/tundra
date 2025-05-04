extends AnimatableBody3D
class_name MovingCastle

@export var heat_dome: HeatDome
@export var castle_maw: Node3D
@export var castle_speed: float = 1.2
@export var castle_on: bool = false

@export var fuel = 1000

signal change_heat_dome_value #value: int
signal change_castle_speed

# TODO: Allow picking new targets on a map or something
# TODO: Rotation, stop at crossroads
#@onready var castle_target: Vector3 = Vector3(0.0, 1.0, 10000.0)

# Internal 
#@onready var _origin: Vector3 = global_position
#@onready var _distance: float = _origin.distance_to(castle_target)
var _velocity: Vector3 = Vector3.ZERO

func _ready():
	Hub.castle = self

	sync_to_physics = false
	set_process(false)
	set_physics_process(false)

	# Player Bones
	set_collision_layer_value(4, true)
	set_collision_mask_value(4, true)

	# Server only?
	NetworkTime.before_tick.connect(_save_previous_position)
	NetworkTime.on_tick.connect(_apply_tick)
	NetworkTime.on_tick.connect(_calc_velocity)

	if multiplayer.is_server():
		# Castle Control Signals (called from Hub.castle)
		change_castle_speed.connect(_on_change_castle_speed)
		change_heat_dome_value.connect(func(new_value): heat_dome.on_change_heat_dome_value(new_value))

@export var speed: float = 0.0

func get_velocity() -> Vector3:
	return _velocity

var prev: Vector3

func _save_previous_position(_delta: float, _tick: int):
	prev = global_position

func _apply_tick(_delta: float, _tick: int):
	translate(Vector3(0.0, 0.0, speed  * _delta))

func _calc_velocity(_delta: float, _tick: int):
	_velocity = (global_position - prev) / NetworkTime.ticktime
	
func _on_change_castle_speed():
	if castle_on:
		castle_on = false
		speed = 0.0
	else:
		castle_on = true
		speed = -1.0
	
