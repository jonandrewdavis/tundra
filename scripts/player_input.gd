extends BaseNetInput
class_name PlayerInput

@onready var parent: CharacterBody3D = get_parent()

var input_dir : Vector2 = Vector2.ZERO
var run_input: bool = false
var shoot_input: bool = false
var jump_input: bool = false
var aim_input: bool = false
var crouch_input: bool = false

var main_menu_input: bool = false
var _main_menu_buffer: bool = false

var static_states: Array[StringName] = [&"Dead", &"Static", &"Ragdoll"]

func _ready():
	super()
	# WARNING: don't forget to _reset if doing input "just once"
	# See: https://foxssake.github.io/netfox/latest/netfox/tutorials/input-gathering-tips-and-tricks/
	NetworkTime.after_tick.connect(func(_dt, _t): _reset())

# TODO: Move all these inputs to _gather() I think. And use "is_fresh"
func _process(_delta):	
	if Input.is_action_just_pressed("main_menu"):
		_main_menu_buffer = true

	if parent._state_machine.state in static_states:
		return

	if Input.is_action_just_pressed("interact"): 
		parent.process_player_input.rpc("interact")

	if Input.is_action_just_pressed("shoot"): 
		parent.process_player_input.rpc("shoot")

	if Input.is_action_just_pressed("weapon_up"):
		parent.process_player_input.rpc("weapon_up")

	if Input.is_action_just_pressed("weapon_down"):
		parent.process_player_input.rpc("weapon_down")

	if Input.is_action_just_pressed("weapon_swap"):
		parent.process_player_input.rpc("weapon_swap")

	if  Input.is_action_just_pressed("reload"):
		parent.process_player_input.rpc("reload")

	if Input.is_action_just_pressed("melee"):
		parent.process_player_input.rpc("melee")

	if Input.is_action_just_pressed("special"):
		parent.process_player_input.rpc("special")

	if Input.is_action_just_pressed("DEBUG_K"):
		parent.process_player_input.rpc("DEBUG_K")

	if Input.is_action_just_pressed("DEBUG_B"):
		parent.process_player_input.rpc("DEBUG_B")

	if Input.is_action_just_pressed("DEBUG_0"):
		parent.process_player_input.rpc("DEBUG_0")

func _gather():
	input_dir = Input.get_vector("left", "right", "forward", "backward")
	run_input = Input.is_action_pressed("run")
	shoot_input = Input.is_action_pressed("shoot")
	jump_input = Input.is_action_pressed("jump")
	aim_input = Input.is_action_pressed("aim")
	crouch_input = Input.is_action_pressed("crouch")

	main_menu_input = _main_menu_buffer
	_main_menu_buffer = false

func _reset():
	_main_menu_buffer = false
