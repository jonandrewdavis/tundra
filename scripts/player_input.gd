extends BaseNetInput
class_name PlayerInput

var input_dir : Vector2 = Vector2.ZERO
var run_input = false
var shoot_input = false
var jump_input = false

func _ready():
	if is_multiplayer_authority():
		super()
	else: 
		set_process(false)

func _process(_delta):
	if Input.is_action_just_pressed("interact"): 
		get_parent().process_player_input.rpc("interact")

	if Input.is_action_just_pressed("shoot"): 
		get_parent().process_player_input.rpc("shoot")

	if Input.is_action_just_pressed("weapon_up"):
		get_parent().process_player_input.rpc("weapon_up")

	if Input.is_action_just_pressed("weapon_down"):
		get_parent().process_player_input.rpc("weapon_down")

	if  Input.is_action_just_pressed("reload"):
		get_parent().process_player_input.rpc("reload")

	if Input.is_action_just_pressed("melee"):
		get_parent().process_player_input.rpc("melee")

	if Input.is_action_just_pressed("special"):
		get_parent().process_player_input.rpc("special")

	if Input.is_action_just_pressed("DEBUG_B"):
		get_parent().process_player_input.rpc("DEBUG_B")

# NOTE: Do not forget to add new inputs to the RollbackSyncronizer!! (IF... you want them to rollback)
# Use this for inputs that are constant or held
func _gather():
	input_dir = Input.get_vector("left", "right", "forward", "backward")
	run_input = Input.is_action_pressed("run")
	shoot_input = Input.is_action_pressed("shoot")
	jump_input = Input.is_action_pressed("jump")
