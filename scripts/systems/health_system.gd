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
@export var regen_delay : int = 5 # Halo 1
@export var regen_increment: int = 1

@onready var sync = $MultiplayerSynchronizer #Note - could be overriden by parent??
@onready var regen_timer: Timer = Timer.new()
@onready var regen_tick_timer: Timer = Timer.new()


signal health_updated
signal died

func _ready() -> void:
	Nodash.sync_property(sync, self, ['max_health'])
	Nodash.sync_property(sync, self, ['health'])

	health_updated.connect(on_update_health)
	died.connect(on_death)
	if multiplayer.is_server():
		prepare_regen_timer()

func _exit_tree() -> void:
	if not multiplayer.is_server():
		Nodash.sync_remove_all(sync)

func damage():
	# Do not allow overkill
	if regen_delay != 0:
		regen_timer.start()
	pass

func heal():
	# Do not allow overheal
	var updated_health = 0
	health_updated.emit(updated_health)
	pass	

func on_update_health(updated_health):
	print('Listening to on_update_health: ', updated_health)
	
# TODO: killed, killer
# TODO: Report the stats to Hub
func on_death():
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
		regen_tick_timer.wait_time = regen_increment
		regen_timer.timeout.connect(regen_health_tick)
		

func start_regen_health():
	if regen_timer.is_stopped() && health < max_health:
		regen_tick_timer.start()
		
func regen_health_tick():
	if regen_timer.is_stopped() && health < max_health:
		regen_tick_timer.start()
	else:
		regen_tick_timer.stop()
