class_name PlayerInput extends Node

var input_dir : Vector2 = Vector2.ZERO
var jump_input := false
var run_input := false
var interact_input := false
var fire_input := false
var switch_up_input := false
var switch_down_input := false
var reload_input := false
var melee_input := false

func _ready():
	NetworkTime.before_tick_loop.connect(_gather)

# NOTE: Do not forget to add new inputs to the RollbackSyncronizer!!
# NOTE: Do not forget to add new inputs to the RollbackSyncronizer!!
func _gather():
	# In this case, should be client authority
	if is_multiplayer_authority():
		input_dir = Input.get_vector("left", "right", "forward", "backward")
		jump_input = Input.is_action_pressed("jump")
		run_input = Input.is_action_pressed("run")
		interact_input = Input.is_action_pressed("interact")
		fire_input = Input.is_action_pressed("shoot")
		# TODO: Difference between just pressed and presed? maybe it's keydown/keyup?
		switch_up_input = Input.is_action_just_pressed("switch_up")
		switch_down_input = Input.is_action_just_pressed("switch_down")
		switch_down_input = Input.is_action_just_pressed("switch_down")
		reload_input = Input.is_action_just_pressed("reload")
		melee_input = Input.is_action_just_pressed("melee")
