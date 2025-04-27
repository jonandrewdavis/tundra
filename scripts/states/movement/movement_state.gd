@tool
# A base movement state for common functions, extend when making new movement state.
# NOTE: This class, MovementState, does not have tick, but contains common functions 
# that each other state should call in tick.

# CRITICAL: Reminder that new states do not have their nodes assigned. This cost me 1 hour
# working with a state I added that did not have an assigned: camera_input, etc.

class_name MovementState 
extends RewindableState

# TODO: Move these into _player
const SPRINT_SPEED_MODIFIER := 1.6
const ROTATION_INTERPOLATE_SPEED := 10
const JUMP_VELOCITY := 6.5
const JUMP_MOVE_SPEED := 3.0

@export var animation_name: String
@export var camera_input : CameraInput
@export var player_input: PlayerInput
@export var parent: Player

var gravity = ProjectSettings.get_setting(&"physics/3d/default_gravity")

func move_player(delta: float):
	var input_dir : Vector2 = get_movement_input()
	
	# Based on https://github.com/godotengine/godot-demo-projects/blob/4.2-31d1c0c/3d/platformer/player/player.gd#L65
	var direction = (camera_input.camera_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var position_target = direction * parent.WALK_SPEED
	
	# Allow movement in the air, a little bit. 
	force_update_is_on_floor()
	if not parent.is_on_floor():
		parent.velocity.y -= gravity * delta
	elif get_run():
		# BUT NO RUNNING in the air
		position_target *= SPRINT_SPEED_MODIFIER

	if position_target:
		parent.velocity = parent.velocity.move_toward(Vector3(position_target.x, parent.velocity.y, position_target.z), parent.ACCELERATION * delta)

	var platform_velocity := Vector3.ZERO
	platform_velocity = get_moving_platform_velocity(delta)

	# https://foxssake.github.io/netfox/netfox/tutorials/rollback-caveats/#characterbody-velocity
	parent.velocity += platform_velocity
	parent.velocity *= NetworkTime.physics_factor
	parent.move_and_slide()
	parent.velocity /= NetworkTime.physics_factor
	parent.velocity -= platform_velocity

# NOTE: Used in Idle to slow down. Includes friction.
# NOTE: Can not leave, see Idle for leaving
func stop_player(delta: float):
	force_update_is_on_floor()
	if not parent.is_on_floor():
		parent.velocity.y -= gravity * delta

	parent.velocity = parent.velocity.move_toward(Vector3(0.0, parent.velocity.y, 0.0), parent.FRICTION * delta)

	var platform_velocity := Vector3.ZERO
	platform_velocity = get_moving_platform_velocity(delta)

	# https://foxssake.github.io/netfox/netfox/tutorials/rollback-caveats/#characterbody-velocity
	parent.velocity += platform_velocity
	parent.velocity *= NetworkTime.physics_factor
	parent.move_and_slide()
	parent.velocity /= NetworkTime.physics_factor
	parent.velocity -= platform_velocity

func rotate_player_model(delta: float):
	var camera_basis : Basis = camera_input.camera_basis
	
	# NOTE: Model direction issues can be resolved by adding a negative to camera_z, depending on setup.
	#var player_lookat_target = -camera_basis.z
	
	var q_from = parent._player_model.global_transform.basis.get_rotation_quaternion()
	var q_to = Transform3D().looking_at(camera_basis.z, Vector3.UP).basis.get_rotation_quaternion()

	var set_model_rotation = Basis(q_from.slerp(q_to, delta * ROTATION_INTERPOLATE_SPEED))
	parent._player_model.global_transform.basis = set_model_rotation

# https://foxssake.github.io/netfox/netfox/tutorials/rollback-caveats/#characterbody-on-floor
func force_update_is_on_floor():
	var old_velocity = parent.velocity
	parent.velocity *= 0
	parent.move_and_slide()
	parent.velocity = old_velocity

func get_moving_platform_velocity(delta: float) -> Vector3:
	var _platform_velocity := Vector3.ZERO
	var collision_result := KinematicCollision3D.new()
	if parent.test_move(parent.global_transform, Vector3.DOWN * delta, collision_result):
		var collider := collision_result.get_collider()
		if collider is MovingCastle:
			var platform := collider as MovingCastle
			_platform_velocity = platform.get_velocity()
			
	return _platform_velocity

func check_for_ragdoll():
	if not parent.bones:
		push_warning("No bones for ragdoll")
	
	if parent.bones.active == true:
		state_machine.transition(&"Ragdoll")


# Are these "get" functions necessary?
func get_movement_input() -> Vector2:
	return player_input.input_dir

func get_run() -> bool:
	return player_input.run_input
	
func get_jump() -> float:
	return player_input.jump_input
