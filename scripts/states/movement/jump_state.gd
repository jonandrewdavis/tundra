@tool
extends MovementState

func enter(_previous_state: RewindableState, _tick: int) -> void:
	parent.velocity.y = JUMP_VELOCITY

func tick(delta, _tick, _is_fresh):
	rotate_player_model(delta)
	move_player(delta)	
	check_for_ragdoll()

	# If issues arise around jump, add additional state transitions here
	force_update_is_on_floor()
	if not parent.is_on_floor():
		state_machine.transition(&"FallState")
