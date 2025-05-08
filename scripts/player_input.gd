extends BaseNetInput
class_name PlayerInput

@onready var parent: CharacterBody3D = get_parent()

var input_dir : Vector2 = Vector2.ZERO
var run_input = false
var shoot_input = false
var jump_input = false
var static_states: Array[StringName] = [&"Dead", &"Static", &"Ragdoll"]

func _ready():
	if is_multiplayer_authority():
		super()
	else: 
		set_process(false)

# TODO: Move all these inputs to _gather() I think. And use "is_fresh"
func _process(_delta):	
	if Input.is_action_just_pressed("DEBUG_B"):
		parent.process_player_input.rpc_id(1, "DEBUG_B")

	if Input.is_action_just_pressed("DEBUG_0"):
		parent.process_player_input.rpc_id(1, "DEBUG_0")

	if parent._state_machine.state in static_states:
		return

	if Input.is_action_just_pressed("interact"): 
		parent.process_player_input.rpc_id(1, "interact")

	if Input.is_action_just_pressed("shoot"): 
		parent.process_player_input.rpc_id(1, "shoot")

	if Input.is_action_just_pressed("weapon_up"):
		parent.process_player_input.rpc_id(1, "weapon_up")

	if Input.is_action_just_pressed("weapon_down"):
		parent.process_player_input.rpc_id(1, "weapon_down")

	if  Input.is_action_just_pressed("reload"):
		parent.process_player_input.rpc_id(1, "reload")

	if Input.is_action_just_pressed("melee"):
		parent.process_player_input.rpc_id(1, "melee")

	if Input.is_action_just_pressed("special"):
		parent.process_player_input.rpc_id(1, "special")


# NOTE: Do not forget to add new inputs to the RollbackSyncronizer!! (IF... you want them to rollback)
# Use this for inputs that are constant or held
func _gather():
	input_dir = Input.get_vector("left", "right", "forward", "backward")
	run_input = Input.is_action_pressed("run")
	shoot_input = Input.is_action_pressed("shoot")
	jump_input = Input.is_action_pressed("jump")


func _exit_tree():
	NetworkTime.before_tick_loop.disconnect(_gather)
