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

var _interact_input := false
var _fire_input := false
var _switch_up_input := false
var _switch_down_input := false
var _reload_input := false
var _melee_input := false

func _ready():
	if is_multiplayer_authority():
		NetworkTime.before_tick_loop.connect(_gather)
	else: 
		set_process(false)
	
var process_count = 0
var gather_count = 0

func _process(_delta):
	if not _interact_input: _interact_input = Input.is_action_just_pressed("interact")
	if not _fire_input: _fire_input = Input.is_action_just_pressed("shoot")
	if not _switch_up_input: _switch_up_input = Input.is_action_just_pressed("switch_up")
	if not _switch_down_input: _switch_down_input = Input.is_action_just_pressed("switch_down")
	if not _switch_down_input: _switch_down_input = Input.is_action_just_pressed("switch_down")
	if not _reload_input: _reload_input = Input.is_action_just_pressed("reload")
	if not _melee_input: _melee_input = Input.is_action_just_pressed("melee")
	
# NOTE: Do not forget to add new inputs to the RollbackSyncronizer!!
# NOTE: Do not forget to add new inputs to the RollbackSyncronizer!!
func _gather():
	# In this case, should be client authority
	input_dir = Input.get_vector("left", "right", "forward", "backward")
	jump_input = Input.is_action_pressed("jump")
	run_input = Input.is_action_pressed("run")
	
	interact_input = _interact_input
	fire_input = _fire_input
	switch_up_input = _switch_up_input
	switch_down_input = _switch_down_input
	switch_down_input = _switch_down_input
	reload_input = _reload_input
	melee_input = _melee_input

	_interact_input = false
	_fire_input = false
	_switch_up_input = false
	_switch_down_input = false
	_switch_down_input = false
	_reload_input = false
	_melee_input = false
