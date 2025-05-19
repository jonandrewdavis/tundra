extends Node
class_name NavigationSystem

@export var nav_agent: NavigationAgent3D
@export var search_box: Area3D

var next_path_pos
var parent: CharacterBody3D

var timer_patrol = Timer.new()
var timer_chase_target = Timer.new()
var timer_navigate = Timer.new()
var timer_give_up = Timer.new()


signal give_up_signal

func _ready() -> void:
	parent = get_parent()

	if not multiplayer.is_server():
		set_physics_process(false)
		set_process(false)
		return

	Nodash.error_missing(nav_agent, 'nav_agent')
	Nodash.error_missing(search_box, 'search_box')

	search_box.body_entered.connect(on_search_box_body_entered)
	search_box.body_exited.connect(on_search_box_body_exited)

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
	timer_give_up.wait_time = 12.0
	timer_give_up.one_shot = true # Do not repeatedly give up

	add_child(timer_patrol)
	timer_patrol.timeout.connect(pick_patrol_destination)
	timer_patrol.wait_time = 60.0
	timer_patrol.start()

func chase_target():
	if timer_chase_target.is_stopped():
		timer_chase_target.start()
	
	var target = parent.target
	if target:
		nav_agent.set_target_position(target.global_transform.origin)
		next_path_pos = nav_agent.get_next_path_position()

func pick_patrol_destination():
	var map = NavigationServer3D.get_maps()[0]
	var random_point = NavigationServer3D.map_get_random_point(map, 1, false)
	
	# The random point should be near-ish to the castle.
	if random_point.distance_to(Hub.castle.global_position) < 150.0:
		nav_agent.set_target_position(random_point)
		next_path_pos = nav_agent.get_next_path_position()
	else:
		pick_patrol_destination()
		
func update_navigation_path():
	if nav_agent.is_navigation_finished() == false:
		next_path_pos = nav_agent.get_next_path_position()

# TODO: Setting & forgetting target might need to be signal emits?
func on_search_box_body_entered(body: Node3D):
	if parent.target:
		return
	
	if body && body.is_in_group('players') or body.is_in_group('player_owned'):
		timer_give_up.stop()
		parent.target = body
		parent.set_state(parent.States.CHASING)

func on_search_box_body_exited(body: Node3D):
	if parent.target == body: 
		timer_give_up.start()

func give_up():
	parent.set_state(parent.States.SEARCHING)
	give_up_signal.emit()
