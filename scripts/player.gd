extends CharacterBody3D
class_name Player

var ROTATION_INTERPOLATE_SPEED = 40.0

const FRICTION = 100
const ACCELERATION = 22.0
const WALK_SPEED := 5.5

@export_category("BAD Template Nodes")

@export var _player_input : PlayerInput
@export var _camera_input : CameraInput
@export var _player_model : Node3D # NOTE: When updating _player_model, also update RollbackSync & TickInterpolater.
@export var _state_machine: RewindableStateMachine
@onready var rollback_synchronizer = $RollbackSynchronizer
var _animation_player: AnimationPlayer

@export_category("Custom Character Nodes")
@export var sync: MultiplayerSynchronizer
@export var skeleton: Skeleton3D
@export var bones: PhysicalBoneSimulator3D
@export var chest: PhysicalBone3D
@export var snow_shader: ColorRect

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
	sync_all_properties()
	rollback_synchronizer.process_settings()

	#TODO: Document cases where this helps prevent jitter. Might not be necessary if fully server authoratitve
	#TODO: Disabling physics on the client might help the server & client not fight over positioning
	#if not multiplayer.is_server():
		#set_physics_process(false)
	#
	#### SERVER ONLY ####
	# TODO: To be fully server authoratitve, this line should be uncommented
	if not multiplayer.is_server():
		return

	_state_machine.state = &"IdleState"
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
	weapon_vertical_tilt()

# NOTE: The way this works is:
# - Process runs in `player_input.gd` 
# - If an input happens, it calls this RPC from the client
# - The resulting RPC only happens on remote (server) ("call_remote" is implied here, but not needed)
# - The `WeaponsManager` uses `MultiplayerSyncronizer` for visiblity, sound, animation_player, etc.
# - This syncs the important properties to all clients (including the local caller [source player]).
# NOTE: Do not add "call_local" or the puppet's weapons_manager can do things.
# TODO: Fully document all the findings from this approach.

# TODO: We should be able to use "is_fresh" from netfox to do "1 time"
# That way we can remove this "is_server" check. Without it, clients were calling to other clients!!
@rpc("any_peer")
func process_player_input(input_string: StringName):
	if not multiplayer.is_server():
		return

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
			interact()
		"special":
			debug_toggle_castle_speed()
		"DEBUG_B":
			toggle_ragdoll()
		"DEBUG_0":
			Hub.debug_create_enemy()

# TODO: Document "Nodash.sync_property"
# TODO: Also sync the Netfox properties. Right now these are just for On Change in MultiplayerSyncronizer 
func sync_all_properties():
	Nodash.warn_missing(_animation_player, '_animation_player')
	Nodash.sync_property(sync, _animation_player, ['active'])
	Nodash.sync_property(sync, _animation_player, ['current_animation'])
	Nodash.sync_property(sync, bones, ['active'])

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
	#debug_increase_heat_dome_radius()
	#debug_toggle_castle_speed()

# NOTE: Ragdoll state is entered with a bones.active check.
# NOTE: See: movement_state.gd and "check_for_ragdoll()"
# TODO: Document that Ragdoll bones are on Layer 3 collision. Adjust weights & poses.
func toggle_ragdoll():
	if bones.active == false:
		_animation_player.active = false
		bones.active = true
		# TODO: ['RightShoulder', 'LeftShoulder', 'RightUpperLeg', 'LeftUpperLeg']
		bones.physical_bones_start_simulation()
		apply_chest_force()
	else:
		_animation_player.active = true
		bones.active = false
		bones.physical_bones_stop_simulation()	

# Apply force away from current facing: -_player_model.basis.z
func apply_chest_force():
	for bone in bones.get_children():
		if bone.bone_name == 'Chest':
			bone.apply_central_impulse(-_player_model.basis.z * -1.0 * 1200.0)

# TODO: Death should be a state
func death():
	print("TODO: PLAYER DIED TEMP MESSAGE")
	toggle_ragdoll()

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
	print("What's the speed before we RPC on client: ", multiplayer.get_remote_sender_id(), ' speed: ', Hub.world.castle_speed)
	if Hub.castle_speed == 0.0:
		Hub.change_castle_speed.emit(2.0)
	else:
		Hub.change_castle_speed.emit(0.0)
