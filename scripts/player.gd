extends CharacterBody3D
class_name Player

var ROTATION_INTERPOLATE_SPEED = 40.0

const FRICTION = 100
const ACCELERATION = 22.0
const DEFAULT_SPEED := 5.5
const SLOW_SPEED := 3.5

var CURRENT_SPEED = DEFAULT_SPEED

@export_category("BAD Template Nodes")
# TODO: I end up refrencing these repeatedly in the project.
# TODO: Evaluate removing "_". Or refactoring to avoid referencing as much.
@export var _player_input : PlayerInput
@export var _camera_input : CameraInput
@export var _player_model : Node3D # NOTE: When updating _player_model, also update RollbackSync & TickInterpolater.
@export var _state_machine: RewindableStateMachine
@onready var rollback_synchronizer = $RollbackSynchronizer
@warning_ignore("unused_private_class_variable")
@export var _tick_interpolator: TickInterpolator

var _animation_player: AnimationPlayer

@export_category("Required Character Nodes")
@export var sync: MultiplayerSynchronizer
@export var skeleton: Skeleton3D
@export var bones: PhysicalBoneSimulator3D
@export var chest: PhysicalBone3D
@export var look_at_right: LookAtModifier3D
@export var look_at_left: LookAtModifier3D
@export var look_at_left_lower: LookAtModifier3D
@export var look_at_target: Node3D

@export_category("Systems")
@export var health_system: HealthSystem
@export var heat_system: HeatSystem

@export_category("FPS Multiplayer Nodes")
@export var weapons_manager: WeaponsManager
@export var weapon_pivot: Marker3D
@export var player_ui: PlayerUI
@export var pvp = false

var peer_id: int
var respawn: bool


# TODO: Heat should be a stat like health, and signals can change it
# TODO: Heat should be a component, like in Forest Bath

# TODO: Port Health system?
# TODO: Port Interaction system?

var interaction_check_timer = Timer.new()

# TODO: remove once debug done
func _input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_cancel'):
		get_tree().quit()

func _enter_tree():
	_player_input.set_multiplayer_authority(str(name).to_int())
	_camera_input.set_multiplayer_authority(str(name).to_int())

# TODO: Programmatically set the Moving Platform properties (For Netfox controller matching)
# TODO: Programmatically set the slope properties
# TODO: Programatically add rollback sync properties: 
# https://foxssake.github.io/netfox/latest/netfox/tutorials/configuring-properties-from-code/

# TODO: Warn if any of our required nodes are missing.
# TODO: abstract this so we can just like, give some nodes
func _ready():
	add_to_group('players')
	#peer_id = str(name).to_int()
	
	# TODO: Hands.
	look_at_right.target_node = look_at_target.get_path()
	look_at_left.target_node = look_at_target.get_path()
	look_at_left_lower.target_node = look_at_target.get_path()

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
	Nodash.sync_property(sync, weapon_pivot, ['rotation'], false)
	Nodash.warn_missing(_animation_player, '_animation_player')
	Nodash.sync_property(sync, _animation_player, ['active'])
	Nodash.sync_property(sync, _animation_player, ['current_animation'])
	Nodash.sync_property(sync, _animation_player, ['speed_scale'], false)
	Nodash.sync_property(sync, bones, ['active'])
	Nodash.sync_property(sync, self, ['pvp'])
	
	_animation_player.playback_default_blend_time = 0.3
	# NOTE: Might not be necessary if fully server authoratitve.
	# TODO: Document cases where this helps prevent jitter.
	# TODO: Disabling physics on the client might help the server & client not fight over positioning
	if not multiplayer.is_server():
		set_physics_process(false)
		set_process(false)
		if multiplayer.get_unique_id() == str(name).to_int():
			NetworkManager.hide_loading()


	#### SERVER ONLY ####
	# TODO: To be fully server authoratitve, this line should be uncommented
	if not multiplayer.is_server():
		return

	_state_machine.state = &"Ragdoll"
	_state_machine.on_display_state_changed.connect(_on_display_state_changed)

	health_system.death.connect(death)


	# TIMERS
	add_child(interaction_check_timer)
	interaction_check_timer.wait_time = 0.2
	interaction_check_timer.start()
	# TODO: better in process
	interaction_check_timer.timeout.connect(interact_check)

	# Allow raycast shooting from camera position
	weapons_manager.player_camera_3D = _camera_input.camera_3D
	weapons_manager.player_input = _player_input

func _exit_tree() -> void:
	if not multiplayer.is_server():
		Nodash.sync_remove_all(sync)

# CRITICAL: Process is turned off for clients.
func _process(_delta: float) -> void:
	#weapon_vertical_tilt()
	on_animation_check()
	

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
			interact()
		"special": # F
			Hub.enemy_system.spawn_dog.emit()
		"DEBUG_B":
			Hub.castle.change_castle_speed.emit()
		"DEBUG_0":
			Hub.enemy_system.spawn_bug_1.emit()


func _rollback_tick(_delta, _tick, _is_fresh):
	if health_system.health == 0:
		_state_machine.transition(&"Dead")

	if respawn == true:
		heat_system.temp = heat_system.max_temp
		health_system.heal(health_system.max_health)
		_state_machine.transition(&"Idle")
		respawn = false

	#if health_system.health == health_system.max_health: 
		#print('respawn')
		#_state_machine.transition(&"Idle")

# TODO: Animations will need to be overhauled completely eventually...
# using a server driven AnimationStateTree (how will that work with rollback, if at all)
# or using sync'd interpolation values (top half / bottom half ).
# For now, try not to over-do it in the prototype phase. Ignore unncessary polish.
const ANIMATION_PREFIX = 'master2/'

func _on_display_state_changed(_old_state: RewindableState, new_state: RewindableState):	
	var animation_name = new_state.animation_name
	if _animation_player && animation_name != "":
		#_animation_player.speed_scale = 1.0
		_animation_player.play(ANIMATION_PREFIX + animation_name)

# TODO: Document that Ragdoll bones are on Layer 3 collision. Adjust weights & poses.

func toggle_ragdoll():
	# CRITICAL: Solve the forced state issue.
	#if _state_machine.state == (&"Ragdoll"):

	if bones.active == true:
		bones.active = false
		_animation_player.active = true
		bones.physical_bones_stop_simulation()

		#_state_machine.transition(&"Ragdoll")
		await get_tree().process_frame
		ragdoll_on_client.rpc()
	else:
		bones.active = true
		_animation_player.active = false
		bones.physical_bones_start_simulation()

		#_state_machine.transition(&"Ragdoll")
		await get_tree().process_frame
		ragdoll_on_client.rpc()
 
@rpc('call_remote')
func ragdoll_on_client():
	#_state_machine.transition(&"Ragdoll")
	
	if bones.active && bones.is_simulating_physics() == false:
		bones.physical_bones_start_simulation()
		
	if bones.active == false && bones.is_simulating_physics() == true:
		bones.physical_bones_stop_simulation()

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
	await get_tree().create_timer(5).timeout
	respawn = true
	pass
	#toggle_ragdoll()
	#_state_machine.transition(&"Dead")
	
#const animations_to_check = [ANIMATION_PREFIX + "rifle run", ANIMATION_PREFIX + "strafe", ANIMATION_PREFIX + "strafe (2)"]	

const MOVES = { 
	'STRAFE': {
		'FAST': [ANIMATION_PREFIX + "strafe", ANIMATION_PREFIX + "strafe (2)"],
		'SLOW': [ANIMATION_PREFIX + "strafe right", ANIMATION_PREFIX + "strafe left"]
	},
	'WALK': {
		'FAST': [ANIMATION_PREFIX + "run backwards", ANIMATION_PREFIX + "rifle run"],
		'SLOW': [ANIMATION_PREFIX + "walking backwards", ANIMATION_PREFIX + "walking"]
	}
}

# TODO: We probably need a "Networked Animation State Tree" to handle blends
# TODO: Could be programmatic via a "AnimationSystem" 
# NOTE: playback_default_blend_time = 0.4
func on_animation_check():
	if _state_machine.state == (&'Move'):
		var _dir = _player_input.input_dir
		var _slowed = _player_input.aim_input

		if _slowed:
			CURRENT_SPEED = SLOW_SPEED
			_animation_player.speed_scale = 1.8
		else:
			CURRENT_SPEED = DEFAULT_SPEED
			_animation_player.speed_scale = 1.0

		# Strafing (no input forward or backwards)
		if _dir.y == 0:
			if _slowed:
				if _dir.x < 0: 
					_animation_player.play(MOVES.STRAFE.SLOW[1]) 
					_animation_player.speed_scale = 1.2 # Slow strafe left is too fast.
				if _dir.x > 0:_animation_player.play(MOVES.STRAFE.SLOW[0])
			else:
				if _dir.x < 0: _animation_player.play(MOVES.STRAFE.FAST[1])
				if _dir.x > 0:_animation_player.play(MOVES.STRAFE.FAST[0])				
		else:
			if _slowed:
				if _dir.y < 0: _animation_player.play(MOVES.WALK.SLOW[1])
				if _dir.y > 0:_animation_player.play(MOVES.WALK.SLOW[0])
			else:
				if _dir.y < 0: _animation_player.play(MOVES.WALK.FAST[1])
				 # No running backwards
				# TODO: Slow factor even more if backwards + aiming?
				if _dir.y > 0: 
					_animation_player.speed_scale = 1.7
					await get_tree().process_frame
					_animation_player.play(MOVES.WALK.SLOW[0])
					CURRENT_SPEED = SLOW_SPEED

# NOTE: -1.0 makes it move the right way and 0.5 dampens it slightly
func weapon_vertical_tilt():
	pass
	#weapon_pivot.rotation.z = clamp(_camera_input.camera_look * -1.0, -0.1, 0.1)

func debug_increase_heat_dome_radius():
	Hub.castle.change_heat_dome_value.emit(1)
	
func debug_toggle_castle_speed():
	Hub.castle.change_castle_speed.emit()


# TODO: Consider moving to an "InteractableSystem", but considering
# only players can interact, all in one script is fine for now
var interactable = null
var holding: Movable = null

func interact_ray_cast():
	var Ray_Origin = _camera_input.camera_3D.project_ray_origin(Hub.viewport/2)
	var Ray_End = (Ray_Origin +  _camera_input.camera_3D.project_ray_normal((Hub.viewport/2)) * 4.0)
	var New_Intersection:PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Ray_Origin,Ray_End)
	New_Intersection.set_collision_mask(00000000_00000000_00000000_10000000) # INTERACTABLES: LAYER 8
	
	# 0: The colliding object
	# 1: The colliding object's ID.
	# 2: The object's surface normal at the intersection point or Vector3.ZERO
	# 3: position: The intersection point.
	var Intersection = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if Intersection.is_empty():
		return null
	
	return Intersection.collider

# INTERACTABLES: LAYER 8
func interact_check():
	var intersect = interact_ray_cast()
	if intersect:
		interactable = intersect
		# TODO: DETACH FROM UI DEPENDENCY (Allow no UI)
		player_ui.update_interaction_label.rpc_id(name.to_int(), intersect.label)
	else:
		if interactable:
			player_ui.update_interaction_label.rpc_id(name.to_int(), '')	
			interactable = null


# TODO: play "nope" sound if not able to do it
# TODO: bind self or something here?
func interact():
	#if holding.is_inside_tree() == false:
		#holding = null
		#return
	if holding and global_position.distance_to(holding.global_position) > 5.0:
		if holding.interact(self):
			holding = null
				
	if holding && interactable == null:
		if holding.interact(self):
			holding = null
		return

	if interactable:
		var interact_result = interactable.interact(self)

		if interact_result == false:
			# TODO: play sound
			return

		if 'enable_pickup' in interactable:
			if interactable.enable_pickup == true && holding == null:
				holding = interactable
			elif interactable.enable_pickup == true && holding:
				holding = null

func interact_holding(item_to_hold):
	holding = item_to_hold
	item_to_hold.interact(self)

@rpc("any_peer")
func update_pvp(new_pvp_value):
	pvp = new_pvp_value
