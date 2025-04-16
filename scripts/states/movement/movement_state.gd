class_name MovementState 
extends RewindableState

# A base movement state for common functions, extend when making new movement state.

# TODO: Move these into _player
const SPRINT_SPEED_MODIFIER := 1.6
const ROTATION_INTERPOLATE_SPEED := 10
const JUMP_VELOCITY := 6.5
const JUMP_MOVE_SPEED := 3.0

@export var animation_name: String
@export var camera_input : CameraInput
@export var player_input: PlayerInput
@export var parent: Player

# Default movement, override as needed
func move_player(_delta: float, _speed: float = parent.WALK_SPEED):
	parent.velocity *= NetworkTime.physics_factor
	parent.move_and_slide()
	parent.velocity /= NetworkTime.physics_factor

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
	if not parent.bones:
		push_warning("No bones")
		return
	
	if parent.bones.active == true:
		state_machine.transition(&"Ragdoll")

	var old_velocity = parent.velocity
	parent.velocity *= 0
	parent.move_and_slide()
	parent.velocity = old_velocity

# Are these "get" functions necessary?
func get_movement_input() -> Vector2:
	return player_input.input_dir

func get_run() -> bool:
	return player_input.run_input
	
func get_jump() -> float:
	return player_input.jump_input
