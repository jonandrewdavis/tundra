extends CharacterBody3D
class_name Player

var ROTATION_INTERPOLATE_SPEED = 40.0

const FRICTION = 100
const ACCELERATION = 22.0
const WALK_SPEED := 5.5

@export_category("BAD Template Nodes")
# TODO: I end up refrencing these repeatedly in the project.
# TODO: Evaluate removing "_". Or refactoring to avoid referencing as much.
@export var _player_input : PlayerInput
@export var _camera_input : CameraInput
@export var _player_model : Node3D # NOTE: When updating _player_model, also update RollbackSync & TickInterpolater.
@export var _state_machine: RewindableStateMachine
@onready var rollback_synchronizer = $RollbackSynchronizer
var _animation_player: AnimationPlayer

@export_category("Required Character Nodes")
@export var sync: MultiplayerSynchronizer
@export var skeleton: Skeleton3D
@export var bones: PhysicalBoneSimulator3D
@export var chest: PhysicalBone3D

@export_category("Systems")
@export var health_system: HealthSystem

@export_category("FPS Multiplayer Nodes")
@export var weapons_manager: WeaponsManager
@export var weapon_pivot: Marker3D
@export var player_ui: CanvasLayer

# TODO: Heat should be a stat like health, and signals can change it
# TODO: Heat should be a component, like in Forest Bath

# TODO: Port Health system?
# TODO: Port Interaction system?

var animation_check_timer = Timer.new()

# TODO: remove once debug done
func _input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_cancel'):
		get_tree().quit()

func _enter_tree():
	set_multiplayer_authority(1)
	_player_input.set_multiplayer_authority(str(name).to_int())
	_camera_input.set_multiplayer_authority(str(name).to_int())

# TODO: Programmatically set the Moving Platform properties (For Netfox controller matching)
# TODO: Programmatically set the slope properties

# TODO: Warn if any of our required nodes are missing.
# TODO: abstract this so we can just like, give some nodes
func _ready():
	add_to_group('players')

	Nodash.error_missing(weapons_manager, 'weapons_manager')
	Nodash.warn_missing(player_ui, 'player_ui')
	
	# Enable input broadcast toggles whether input properties 
	# are broadcast to all peers, or only to the server.
	# The default is true to support legacy behaviour. 
	# It is recommended to turn this off. 
	$RollbackSynchronizer.enable_input_broadcast = false

	#### CLIENT & SERVER ####
	# https://foxssake.github.io/netfox/netfox/tutorials/responsive-player-movement/#ownership
	_animation_player = _player_model.get_node("AnimationPlayer")
	rollback_synchronizer.process_settings()
	
	# MultiplayerSyncronizer properties
	Nodash.warn_missing(_animation_player, '_animation_player')
	Nodash.sync_property(sync, _animation_player, ['active'])
	Nodash.sync_property(sync, _animation_player, ['current_animation'])
	Nodash.sync_property(sync, bones, ['active'])

	#TODO: Document cases where this helps prevent jitter. Might not be necessary if fully server authoratitve
	#TODO: Disabling physics on the client might help the server & client not fight over positioning
	#if not multiplayer.is_server():
		#set_physics_process(false)

	#### SERVER ONLY ####
	# TODO: To be fully server authoratitve, this line should be uncommented
	if not multiplayer.is_server():
		return

	health_system.death.connect(death)

	_state_machine.state = &"Idle"
	_state_machine.on_display_state_changed.connect(_on_display_state_changed)

	# TIMERS
	add_child(animation_check_timer)
	animation_check_timer.wait_time = 0.2
	animation_check_timer.start()
	animation_check_timer.timeout.connect(on_animation_check)

	# Allow raycast shooting from camera position
	weapons_manager.player_camera_3D = _camera_input.camera_3D
	weapons_manager.player_input = _player_input

func _exit_tree() -> void:
	if not multiplayer.is_server():
		Nodash.sync_remove_all(sync)

func _process(_delta: float) -> void:
	# NOTE: Runs on the client.
	print(_state_machine.state)
	weapon_vertical_tilt()
	#ragdoll_on_client()

# NOTE: The way this works is:
# - Process runs in `player_input.gd` 
# - If an input happens, it calls this RPC with id from the client
# - The `WeaponsManager` uses `MultiplayerSyncronizer` for visiblity, sound, animation_player, etc.
# - This syncs the important properties to all clients (including the local caller [source player]).
# NOTE: Do not add "call_local" or the puppet's weapons_manager can do things.
# TODO: Fully document all the findings from this approach.

# TODO: We should be able to use "is_fresh" from netfox to do "1 time"
# That way we can remove this "is_server" check. Without it, clients were calling to other clients!!

# NOTICE: Updated to be an rpc_id(1) from any peer. This makes the player client call
# directly to the server on it's matching player node. Avoids broadcasting local client inputs to other clients.
@rpc('any_peer')
func process_player_input(input_string: StringName):
	match input_string:
		"weapon_up":
			weapons_manager.change_weapon(weapons_manager.CHANGE_DIR.UP)
		"weapon_down":
			weapons_manager.change_weapon(weapons_manager.CHANGE_DIR.DOWN)
		"shoot":
			weapons_manager.shoot()
		"reload":
			weapons_manager.reload()
		"melee":
			weapons_manager.melee()
		"interact":
			debug_increase_heat_dome_radius()
		"special":
			debug_toggle_castle_speed()
		"DEBUG_B":
			debug_toggle_ragdoll()
		"DEBUG_0":
			Hub.debug_create_enemy()

# TODO: Animations will need to be overhauled completely eventually...
# using a server driven AnimationStateTree (how will that work with rollback, if at all)
# or using sync'd interpolation values (top half / bottom half ).
# For now, try not to over-do it in the prototype phase. Ignore unncessary polish.
const ANIMATION_PREFIX = 'master_x_bot_animations/'

func _on_display_state_changed(_old_state: RewindableState, new_state: RewindableState):	
	var animation_name = new_state.animation_name
	if _animation_player && animation_name != "":
		if animation_name == "rifle run" && _player_input.input_dir.y == 0:
			if _player_input.input_dir.x > 0:
				_animation_player.play(ANIMATION_PREFIX + "strafe")
			else:
				_animation_player.play(ANIMATION_PREFIX + "strafe (2)")
		else:
			_animation_player.play(ANIMATION_PREFIX + animation_name)

func interact():
	pass

# TODO: Document that Ragdoll bones are on Layer 3 collision. Adjust weights & poses.

func debug_toggle_ragdoll():
	if _state_machine.state == (&"Ragdoll"):
		_state_machine.transition(&"Idle")
	else:
		_state_machine.transition(&"Ragdoll")
	
func ragdoll_on_client():
	if bones.active && bones.is_simulating_physics() == false:
		bones.physical_bones_start_simulation()
		
	if bones.active == false && bones.is_simulating_physics() == true:
		bones.physical_bones_stop_simulation()

	#if bones.active == false:
		#_animation_player.active = false
		#bones.active = true
		## TODO: ['RightShoulder', 'LeftShoulder', 'RightUpperLeg', 'LeftUpperLeg']
		## CRITICAL: Fix force
		##apply_chest_force()
	#else:
		#_animation_player.active = true
		#bones.active = false
		#bones.physical_bones_stop_simulation()	

# Apply force away from current facing: -_player_model.basis.z
func apply_chest_force():
	for bone in bones.get_children():
		if bone.bone_name == 'Chest':
			bone.apply_central_impulse(-_player_model.basis.z * -1.0 * 1200.0)

# TODO: Death should be a state
# TESTING: How would ragdoll & death interact?
# TESTING: How do we prevent input during these states
# TESTING: Also think about "Locked" activities
func death():
	_state_machine.transition(&"Dead")
	await get_tree().create_timer(10).timeout
	respawn()

func respawn():
	health_system.heal(health_system.max_health)
	_state_machine.transition(&"Idle")

const animations_to_check = [ANIMATION_PREFIX + "rifle run", ANIMATION_PREFIX + "strafe", ANIMATION_PREFIX + "strafe (2)"]	

# TODO: refactor animations completely
func on_animation_check():
	if not _animation_player.current_animation in animations_to_check:
		return
	
	if _player_input.input_dir.y == 0:
		if _player_input.input_dir.x > 0:
			_animation_player.play(ANIMATION_PREFIX + "strafe")
		else:
			_animation_player.play(ANIMATION_PREFIX + "strafe (2)")
	
	if _player_input.input_dir.y != 0:
		_animation_player.play(ANIMATION_PREFIX + "rifle run")

# NOTE: -1.0 makes it move the right way and 0.5 dampens it slightly
func weapon_vertical_tilt():
	weapon_pivot.rotation.z = clamp(_camera_input.camera_look * -1.0, -0.5, 0.5)

func debug_increase_heat_dome_radius():
	Hub.heat_dome_value.emit(1)

func debug_toggle_castle_speed():
	Hub.debug_change_castle_speed()
