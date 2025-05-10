extends Node
class_name HealthSystem

# TODO: HealthBars, do we want them to show on enemies? 
# Helldivers 2 does not, but there are other indicators (bleeding, fatigue)
# On a related note, could show small white damage numbers too...

# TODO: could emit "MAJOR HURT" and "MINOR HURT" that the parent could react to

@export var max_health : int = 100
@onready var health = max_health

# TODO: Shield system? Halo / Apex, etc?
# NOTE: Halo 1's shield regen is about 5 seconds
@export var regen_enabled: bool = false
@export var regen_delay: float = 5.5 # Halo 1
@export var regen_speed: float = 0.15
@export var regen_increment: int = 2

@export var max_temp : int = 11
@export var min_temp : int = -40
@onready var temp = max_temp

@export var temp_enabled: bool = false
@export var temp_regen_speed: float = 0.15
@export var temp_regen_increment: float = 0.5

@onready var regen_timer: Timer = Timer.new()
@onready var regen_tick_timer: Timer = Timer.new()
@onready var temp_timer: Timer = Timer.new()

var last_damage_source := 0

@warning_ignore("unused_signal")
signal hurt
signal health_updated
signal temp_updated
signal max_health_updated
signal death

# NOTE: If used, could be overriden to be the parent's sync, reducing # of syncs
#@onready var sync = $MultiplayerSynchronizer 

func _ready() -> void:
	
	# NOTE: May need a syncronizer to display to other clients
	# Like if we decide to use the floating health display

	#Nodash.sync_property(sync, self, ['max_health'])
	#Nodash.sync_property(sync, self, ['health'])
	
	if multiplayer.is_server():
		death.connect(on_report_death)
		
		# CAUTION: Recieved Node not found & process_rpc errors if this heal is not delayed
		await get_tree().process_frame
		heal(max_health)
		max_health_updated.emit(max_health)
		
		if regen_enabled:
			# CRITICAL: This requires `call_deferred` for some reason...
			call_deferred('prepare_regen_timer')
	
		if temp_enabled:
			add_child(temp_timer)
			temp_timer.wait_time = temp_regen_speed
			temp_timer.timeout.connect(on_temp_timer)
			temp_timer.start()
#func _exit_tree() -> void:
	#if not multiplayer.is_server():
		#Nodash.sync_remove_all(sync)
		
# TODO: could do teams here
func damage(value: int, source: int = 0) -> bool:
	# Don't allow negative values when damaging
	var next_health = health - abs(value)
	
	if allow_damage_from_source(source) == false:
		return false
	
	# Do not allow damage when dead.
	if health == 0:
		return false

	# Do not allow overkill. Just die.
	if next_health <= 0:
		regen_timer.stop()
		health = 0
		last_damage_source = source
		health_updated.emit(0)
		hurt.emit()
		death.emit()
		return true
	
	# Valid damage, not dead
	last_damage_source = source
	health = next_health
	health_updated.emit(next_health)
	hurt.emit()

	if regen_enabled:
		regen_timer.start()
	
	return true

# TODO: Could also implement "teams" here. 
# 0 is enemy fire
func allow_damage_from_source(source):
	# Health system has to have a parent. 
	var parent = get_parent()

	# Enemies can not hurt each other.
	if not parent.is_in_group("players") and source == 0:
		return false
		
	# Player rules
	if parent.is_in_group("players"):
		# PVP is off	
		if source != 0 and parent.pvp == false:
			return false

		# PVP is on
		elif source != 0 and parent.pvp == true:
			return true
		
	return true

func heal(value):
	var next_health = health + abs(value)
	
	# Do not allow overheal
	if next_health > max_health:
		next_health = max_health
	
	health = next_health
	health_updated.emit(health)


# TODO: killed, killer
# TODO: Report the stats to Hub
func on_report_death():
	print('TODO: Reporting the death of a player')
	pass

# TODO: Could abstract this system to handle regen of any property, like HEAT.
# OR FATIGUE
func prepare_regen_timer():
	if regen_enabled:
		regen_timer.wait_time = regen_delay
		regen_timer.one_shot = true
		add_child(regen_timer)
		regen_timer.timeout.connect(start_regen_health)
		
		regen_tick_timer.wait_time = regen_speed # regen_speed?
		add_child(regen_tick_timer)
		regen_tick_timer.timeout.connect(regen_health_tick)

func start_regen_health():
	if regen_timer.is_stopped() && health < max_health:
		last_damage_source = 0
		regen_tick_timer.start()

func regen_health_tick():
	if regen_timer.is_stopped() && health < max_health:
		heal(regen_increment)
		regen_tick_timer.start()
	else:
		regen_tick_timer.stop()

func on_temp_timer():
	temp = temp + temp_regen_increment	
	temp_updated.emit(temp)
