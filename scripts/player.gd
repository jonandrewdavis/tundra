extends CharacterBody3D
class_name Player

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var interactable
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

var animation_check_timer = Timer.new()

# TODO: remove once debug done
func _input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_cancel'):
		get_tree().quit()

func _enter_tree():
	set_multiplayer_authority(1)
	_player_input.set_multiplayer_authority(str(name).to_int())
	_camera_input.set_multiplayer_authority(str(name).to_int())


# TODO: Warn if any of our required nodes are missing.
func _ready():
	if !weapons_manager:
		push_error("No Weapons Manager")
		return
	
	#### CLIENT & SERVER ####

	add_to_group('players')
	# TODO: This is here due to ragdoll's call local
	_animation_player = _player_model.get_node("AnimationPlayer")
	# call this after setting authority
	# https://foxssake.github.io/netfox/netfox/tutorials/responsive-player-movement/#ownership
	rollback_synchronizer.process_settings()
	sync_all_properties()

	#TODO: Document cases where this helps prevent jitter.
	#TODO: Disabling physics on the client helps the server & client not fight over positioning
	#NOTE: We might need _physics_process to run on the client, depedning on what we're doing.. camera tilt, etc.
	#if not multiplayer.is_server():
		#set_physics_process(false)
	
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


var is_in_heat_dome = false

func _process(_delta: float) -> void:
	# Runs on the client.
	if global_position.distance_to(Hub.heat_dome.global_position) <= Hub.heat_dome.heat_dome_radius:
		is_in_heat_dome = false
		show_snow_shader(false)
	else:
		is_in_heat_dome = true
		show_snow_shader(true)

func _physics_process(_delta: float) -> void:
	weapon_vertical_tilt()

func _rollback_tick(delta: float, _tick: int, _is_fresh: bool) -> void:
	_force_update_is_on_floor()
	if not is_on_floor():
		apply_gravity(delta)

# TODO: Fully document all the findings from this approach.
# NOTE: The way this works is:
# - Process runs in `player_input.gd` 
# - If an input happens, it calls this RPC from the client
# - The resulting RPC only happens on remote (server) ("call_remote" is implied here, but not needed)
# - The `WeaponsManager` uses `MultiplayerSyncronizer` for visiblity, sound, animation_player, etc.
# - This syncs the important properties to all clients (including the local caller [source player]).
# NOTE: Do not add "call_local" or the puppet's weapons_manager can do things.
@rpc("any_peer")
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
			interact()
		"special":
			debug_toggle_castle_speed()
		"DEBUG_B":
			# NOTE: Skeletons are a local RPC
			toggle_ragdoll.rpc()
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

func apply_gravity(delta):
	velocity.y -= gravity * delta

func _force_update_is_on_floor():
	var old_velocity = velocity
	velocity *= 0
	move_and_slide()
	velocity = old_velocity

func interact():
	#debug_increase_heat_dome_radius()
	debug_toggle_castle_speed()

# TODO: Document that Ragdoll bones are on Layer 3 collision.
# TODO: Adjust influence. Move to state, change input allowed, etc.
# SPECIAL CASE: ONLY THING ALLOWED TO BE CALL LOCAL.
@rpc("any_peer", 'call_local')
func toggle_ragdoll():
	if bones.active == false:
		_animation_player.active = false
		bones.active = true
		# ['RightShoulder', 'LeftShoulder', 'RightUpperLeg', 'LeftUpperLeg']
		bones.physical_bones_start_simulation()
		apply_chest_force()
	else:
		_animation_player.active = true
		bones.active = false
		bones.physical_bones_stop_simulation()	

# Apply force away from current facing: -_player_model.basis.z
func apply_chest_force():
	for bone in bones.get_children():
		if bone.bone_name == 'Hips':
			bone.apply_central_impulse(-_player_model.basis.z * -1.0 * 1200.0)

# TODO: Death should be a state
func death():
	global_position = Vector3(10.0, 10.0, 10.0)
	$TickInterpolator.teleport()

func debug_increase_heat_dome_radius():
	Hub.heat_dome_value.emit(1)

func debug_toggle_castle_speed():
	#print("What's the speed before we RPC on client: ", multiplayer.get_remote_sender_id(), ' speed: ', Hub.world.castle_speed)
	if Hub.castle_speed == 0.0:
		Hub.change_castle_speed.emit(2.0)
	else:
		Hub.change_castle_speed.emit(0.0)

const animations_to_check = [ANIMATION_PREFIX + "rifle run", ANIMATION_PREFIX + "strafe", ANIMATION_PREFIX + "strafe (2)"]	

# TODO: refactor animations
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

func show_snow_shader(value: bool):
	snow_shader.visible = value

############### SERVER - camera_vertical_tilt #################
# NOTE: This mostly works, but it's better to just use a regular multiplayer syncronizer
# TODO: If netowrk traffic is too high, look into fixing the bugs with this in physics:
	#if multiplayer.is_server():
		#camera_vertical_tilt()
#func camera_vertical_tilt():
	#_camera_input.camera_3D.rotation.x = _camera_input.camera_look
	#pass

func weapon_vertical_tilt():
	weapon_pivot.rotation.z = clamp(_camera_input.camera_look * -1.0, -0.5, 0.5)

func sync_path(node, properties: Array[String]):
	sync.replication_config.add_property(str(node.get_path()) + ':' + ":".join(properties))

func sync_all_properties():
	sync_path(_animation_player, ['active'])
	sync_path(_animation_player, ['current_animation'])
	sync_path(bones, ['active'])
	for property_path in sync.replication_config.get_properties():
		sync.replication_config.property_set_replication_mode(property_path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)	
