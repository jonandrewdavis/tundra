extends CharacterBody3D
class_name Player

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var interactable

var speed_modifier: float = 0.0

@export_category("BAD Template Variables")

@export var _player_input : PlayerInput
@export var _camera_input : CameraInput
@export var _player_model : Node3D
@export var _state_machine: RewindableStateMachine
@export var skeleton: Skeleton3D
@export var bones: PhysicalBoneSimulator3D
@export var chest: PhysicalBone3D

@onready var rollback_synchronizer = $RollbackSynchronizer
var _animation_player

@export_category("FPS Multiplayer")
@export var weapons_manager: WeaponsManager
@export var WeaponPivot: Marker3D

# TODO: remove once debug done
func _input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_cancel'):
		get_tree().quit()

func _enter_tree():
	set_multiplayer_authority(1)
	_player_input.set_multiplayer_authority(str(name).to_int())
	_camera_input.set_multiplayer_authority(str(name).to_int())

func _ready():
	# Default state
	_state_machine.state = &"IdleState"
	_animation_player = _player_model.get_node("AnimationPlayer")

	# TODO: can this be moved to movement_state
	_state_machine.on_display_state_changed.connect(_on_display_state_changed)

	# call this after setting authority
	# https://foxssake.github.io/netfox/netfox/tutorials/responsive-player-movement/#ownership
	rollback_synchronizer.process_settings()
	
	# Allow raycast shooting from camera position
	weapons_manager.player_camera_3D = _camera_input.camera_3D
	weapons_manager.player_input = _player_input
#
	#TODO: Document cases where this helps prevent jitter.
	#TODO: Disabling physics on the client helps the server & client not fight over positioning
	if multiplayer.is_server() == false:
		set_physics_process(false)
		

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

# NOTE: Do not add "call_local" or the puppet's weapons_manager can do things. We should ignore those
# in order to be deterministic / reliable. Basically, trying to run this: local authorative, but
# in server rollback sucked. Still don't fully understand.

@rpc("any_peer", "call_local", "reliable")
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

# TODO: Use statemachine to transition in AnimationStateTre
# TODO: every or just sync: the interpolation
func _on_display_state_changed(_old_state, new_state):	
	var animation_name = new_state.animation_name
	if _animation_player && animation_name != "":
		if animation_name == "rifle run" && _player_input.input_dir.y == 0:
			if _player_input.input_dir.x > 0:
				_animation_player.play("strafe")
			else:
				_animation_player.play("strafe (2)")
		else:
			_animation_player.play(animation_name)

func apply_gravity(delta):
	velocity.y -= gravity * delta

func _force_update_is_on_floor():
	var old_velocity = velocity
	velocity *= 0
	move_and_slide()
	velocity = old_velocity

func interact():
	toggle_ragdoll()
	pass

# TODO: Document that Ragdoll bones are on Layer 3 collision.
# TODO: Adjust influence. Move to state, change input allowed, etc.
func toggle_ragdoll():
	if bones.active == false:
		_animation_player.active = false
		bones.active = true
		# ['RightShoulder', 'LeftShoulder', 'RightUpperLeg', 'LeftUpperLeg']
		bones.physical_bones_start_simulation()
		apply_chest_force()
		set_collision_layer_value(1, true)
	else:
		_animation_player.active = true
		bones.active = false
		bones.physical_bones_stop_simulation()
		set_collision_layer_value(1, false)
		

# Apply force away from current facing: -_player_model.basis.z
func apply_chest_force():
	for bone in bones.get_children():
		if bone.bone_name == 'Chest':
			bone.apply_central_impulse(-_player_model.basis.z * -1.0 * 250.0)

func death():
	speed_modifier = -100.0
	await get_tree().create_timer(2.0).timeout
	respawn()

func respawn():
	global_position = Vector3(2.0, 2.0, 2.0)
	speed_modifier = 0.0
