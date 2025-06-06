extends AnimatableBody3D



class_name MovingCastle

@export var heat_dome: HeatDome
@export var castle_maw: Node3D
@export var castle_speed: float = 1.2
@export var castle_on: bool = false
@export var health_system: HealthSystem

@export var fuel: float = 1000

signal change_heat_dome_value #value: int
signal change_castle_speed
signal fuel_updated
signal distance_travelled_updated

@onready var castle_deposit_box = $CastleDepositBox

var origin_at_death = 0.0
var distance_travelled: float = 0.00
var fuel_timer = Timer.new()

# TODO: Allow picking new targets on a map or something
# TODO: Rotation, stop at crossroads
#@onready var castle_target: Vector3 = Vector3(0.0, 1.0, 10000.0)

# Internal 
#@onready var _origin: Vector3 = global_position
#@onready var _distance: float = _origin.distance_to(castle_target)
@export var _velocity: Vector3 = Vector3.ZERO

func _ready():
	Hub.castle = self
	
	add_to_group('targets')
	add_to_group('player_owned')

	sync_to_physics = false
	set_process(false)
	set_physics_process(false)

	# Player Bones
	set_collision_layer_value(4, true)
	set_collision_mask_value(4, true)


	if multiplayer.is_server():
		# Castle Control Signals (called from Hub.castle)
		change_castle_speed.connect(_on_change_castle_speed)
		change_heat_dome_value.connect(func(new_value): heat_dome.on_change_heat_dome_value(new_value))
	
		# Server only?
		NetworkTime.before_tick.connect(_save_previous_position)
		NetworkTime.on_tick.connect(_apply_tick)
		NetworkTime.on_tick.connect(_calc_velocity)
		
		add_child(fuel_timer)
		fuel_timer.wait_time = 2.0
		fuel_timer.start()
		fuel_timer.timeout.connect(consume_fuel)
		
		health_system.hurt.connect(func(): on_castle_hurt.rpc())
		health_system.death.connect(func(): origin_at_death = global_position.z)


@export var speed: float = 0.0

func get_velocity() -> Vector3:
	return _velocity

var prev: Vector3

func _save_previous_position(_delta: float, _tick: int):
	prev = global_position

func _apply_tick(_delta: float, _tick: int):
	translate(Vector3(0.0, 0.0, speed  * _delta))

func _calc_velocity(_delta, _tick: int):
	# CRITICAL: Figure out how keep a cache of velocities. It should remain the same
	# if 0. And not double.
	
	# Sometimes velocity is doubled.
	# Sometimes velocity is 0.0
	_velocity = ((global_position - prev) / NetworkTime.ticktime)
	
func _on_change_castle_speed():
	if castle_on:	
		play_industrial_sounds.rpc(false)
		castle_on = false
		speed = 0.0
	else:
		play_industrial_sounds.rpc(true)
		castle_on = true
		speed = -1.2
	
	rpc_down.rpc(!castle_on)

@rpc("authority")
func rpc_down(on_off):
	if on_off:	
		castle_on = false
		speed = 0.0
	else:
		on_off = true
		speed = -1.2
		
func consume_fuel():
	if Hub.player_container.get_child_count() == 0:
		castle_on = false
		speed = 0.0
		return
	
	var next_fuel
	if castle_on:
		next_fuel = fuel - 1.4
	else:
		next_fuel = fuel - 0.3
	
	next_fuel = clamp(next_fuel, 0, 1000)
	if next_fuel == 0:
		turn_castle_off()
		
	fuel = next_fuel
	fuel_updated.emit(fuel)

	distance_travelled = abs(origin_at_death - global_position.z)
	distance_travelled_updated.emit(distance_travelled / 1000)

func gain_fuel(fuel_amount: int):
	var next_fuel = fuel + fuel_amount
	next_fuel = clamp(next_fuel, 0, 1000)
	fuel = next_fuel
	fuel_updated.emit(fuel)

@rpc
func on_castle_hurt():
	$CastleHurtSound.play()

@rpc
func play_industrial_sounds(sound_is_on):
	if sound_is_on:
		$CastleIndustrialSounds.play()
	else:
		$CastleIndustrialSounds.stop()


func turn_castle_off():
	play_industrial_sounds.rpc(false)
	castle_on = false
	speed = 0.0
	
