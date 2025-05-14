extends Node
class_name HeatSystem

const MAX_DISTANCE = 80

signal temp_updated
signal update_fog
signal low_temperature_warning

@export var max_temp : float = 74.0
@export var min_temp : float = -40.0

@export var temp = max_temp
@export var temp_regen_speed: float = 1.0
@export var temp_regen_increment: float = 5.0

@onready var temp_timer: Timer = Timer.new()
@onready var freeze_timer: Timer = Timer.new()
@onready var freeze_damage_timer: Timer = Timer.new()
@onready var fog_timer: Timer = Timer.new()


# TODO: What if ... This system took a node to mount connect its signals to.
# The only trick would be target it's % labels
# (connect, bind)

var player: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not multiplayer.is_server():
		return

	player = get_parent()

	add_child(temp_timer)
	temp_timer.wait_time = temp_regen_speed
	temp_timer.timeout.connect(on_temp_timer)
	temp_timer.start()

	add_child(freeze_timer)
	freeze_timer.wait_time = 10.0
	freeze_timer.timeout.connect(start_freezing)
	freeze_timer.one_shot = true

	add_child(freeze_damage_timer)
	freeze_damage_timer.wait_time = 0.5
	freeze_damage_timer.timeout.connect(on_freeze_damage)
	freeze_damage_timer.one_shot = false
	
	# Note: change lerp 
	add_child(fog_timer)
	fog_timer.wait_time = 1.0
	fog_timer.timeout.connect(on_fog_update_timer)
	fog_timer.start()

func on_temp_timer():
	var player_pos = player.position
	var distance = player_pos.distance_to(Hub.castle.position)

	var inner = distance <= Hub.castle.heat_dome.heat_dome_radius - 5.0
	var inside_dome = distance <= Hub.castle.heat_dome.heat_dome_radius
	var outside_dome = distance > Hub.castle.heat_dome.heat_dome_radius
	var outside_max = distance > Hub.castle.heat_dome.heat_dome_radius + MAX_DISTANCE

	if inner:
		temp_regen_increment = 16.0 * 1.0
	elif inside_dome:
		temp_regen_increment = 8.0 * 1.0
	elif outside_max:
		temp_regen_increment = distance * -1.0
	elif outside_dome:
		temp_regen_increment = distance / 16 * -1.0

	var new_temp = temp + temp_regen_increment

	# Prevent overheating.
	if new_temp >= max_temp:
		new_temp = max_temp
	elif new_temp <= min_temp:
		new_temp = min_temp

	temp = new_temp
	temp_updated.emit(new_temp)
	
	start_freeze_warning()

func on_fog_update_timer():
	if player.position.distance_to(Hub.castle.position) > MAX_DISTANCE:
		update_fog.emit(0.02 + player.position.distance_to(Hub.castle.position) / 800.0)
	else:
		update_fog.emit(0.02)

func start_freezing():
	freeze_damage_timer.start()

func on_freeze_damage():
	player.health_system.damage(2)

func start_freeze_warning():	
	if (freeze_timer.is_stopped() && temp == min_temp):
		freeze_timer.start(8.0)
		low_temperature_warning.emit(true)
	elif temp > min_temp:
		freeze_timer.stop()
		low_temperature_warning.emit(false)

	if freeze_damage_timer.is_stopped() == false:
		if temp > min_temp:
			freeze_damage_timer.stop()
			low_temperature_warning.emit(false)
