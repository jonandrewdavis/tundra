extends Node
class_name NavigationSystem

@export var nav_agent: NavigationAgent3D

var next_path_pos
var parent: CharacterBody3D

var timer_chase_target = Timer.new()
var timer_navigate = Timer.new()
var timer_give_up = Timer.new()

signal give_up_signal
@warning_ignore("unused_signal")
signal attack_signal

func _ready() -> void:
	parent = get_parent()

	if not multiplayer.is_server():
		set_physics_process(false)
		set_process(false)
		return

	Nodash.error_missing(nav_agent, 'nav_agent')

	# Navigation
	add_child(timer_navigate)
	timer_navigate.timeout.connect(update_navigation_path)
	timer_navigate.wait_time = randf_range(0.1, 0.5)
	timer_navigate.one_shot = false
	timer_navigate.start()

	# Timers
	add_child(timer_chase_target)
	timer_chase_target.timeout.connect(chase_target)
	timer_chase_target.wait_time = randf_range(4.0, 7.0)
	timer_chase_target.one_shot = false
	
	add_child(timer_give_up)
	timer_give_up.timeout.connect(give_up)
	timer_give_up.wait_time = 10.0
	timer_give_up.one_shot = true # Do not repeatedly give up

func chase_target():
	if timer_chase_target.is_stopped():
		timer_chase_target.start()
	
	var target = parent.target
	if target:
		if parent.global_position.distance_to(target.global_transform.origin) > 3.0:
			nav_agent.set_target_position(target.global_transform.origin)
			next_path_pos = nav_agent.get_next_path_position()
			
	if nav_agent.is_navigation_finished():
		parent.attack()

func pick_patrol_destination():
	var map = NavigationServer3D.get_maps()[0]
	var random_point = NavigationServer3D.map_get_random_point(map, 1, false)
	nav_agent.set_target_position(random_point)
	next_path_pos = nav_agent.get_next_path_position()
	
func update_navigation_path():
	if nav_agent.is_navigation_finished() == false:
		next_path_pos = nav_agent.get_next_path_position()

func give_up():
	give_up_signal.emit()
