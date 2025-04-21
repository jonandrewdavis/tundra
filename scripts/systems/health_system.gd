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
@export var regen_delay: float = 5.5 # Halo 1
@export var regen_speed: float = 0.15
@export var regen_increment: int = 2

#@onready var sync = $MultiplayerSynchronizer #Note - could be overriden by parent??
@onready var regen_timer: Timer = Timer.new()
@onready var regen_tick_timer: Timer = Timer.new()

signal health_updated
signal max_health_updated
signal death
# TODO:
#signal revive

func _ready() -> void:
	# NOTICE: May need a syncronizer to display to other clients
	# ike if we decide to use the floating health display
	#Nodash.sync_property(sync, self, ['max_health'])
	#Nodash.sync_property(sync, self, ['health'])
	
	if multiplayer.is_server():
		call_deferred('prepare_regen_timer')
		health_updated.connect(broadcast_stub)
		death.connect(on_death)

		# CAUTION: Recieved Node not found & process_rpc errors if this is not delayed
		await get_tree().process_frame
		heal(max_health)

#func _exit_tree() -> void:
	#if not multiplayer.is_server():
		#Nodash.sync_remove_all(sync)

func damage(value: int):
	# Don't allow negative values when damaging
	var next_health = health - abs(value)

	# Do not allow overkill
	if next_health <= 0:
		regen_timer.stop()
		health_updated.emit(0)
		death.emit()
		return
	
	# Valid damage, not dead
	health = next_health
	health_updated.emit(next_health)
	if regen_delay != 0:
		regen_timer.start()
		

func heal(value):
	var next_health = health + abs(value)
	
	# Do not allow overheal
	if next_health > max_health:
		next_health = max_health
	
	health = next_health
	health_updated.emit(health)

func broadcast_stub(_health):
	var target_id = int(get_parent().name)
	if target_id:
		broadcast_heath_signal.rpc_id(target_id, _health)

@rpc('authority')
func broadcast_heath_signal(updated_health):
	health_updated.emit(updated_health)
	max_health_updated.emit(max_health)
	
# TODO: killed, killer
# TODO: Report the stats to Hub
func on_death():
	print("PLAYER DIED fOR REAL")
	pass

# TODO: Could abstract this to handle regen of any property, like HEAT.
# OR FATIGUE
func prepare_regen_timer():
	if regen_delay != 0:
		add_child(regen_timer)
		regen_timer.wait_time = regen_delay
		regen_timer.one_shot = true
		regen_timer.timeout.connect(start_regen_health)
		
		add_child(regen_tick_timer)
		regen_tick_timer.wait_time = regen_speed # regen_speed?
		regen_tick_timer.timeout.connect(regen_health_tick)

func start_regen_health():
	if regen_timer.is_stopped() && health < max_health:
		regen_tick_timer.start()
		
func regen_health_tick():
	if regen_timer.is_stopped() && health < max_health:
		heal(regen_increment)
		regen_tick_timer.start()
	else:
		regen_tick_timer.stop()
