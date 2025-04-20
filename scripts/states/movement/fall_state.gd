@tool
extends MovementState

func tick(delta, _tick, _is_fresh):
	rotate_player_model(delta)
	move_player(delta)
	check_for_ragdoll()

	if parent.is_on_floor():
		if get_movement_input() == Vector2.ZERO:
			state_machine.transition(&"IdleState")
		elif get_movement_input() != Vector2.ZERO:
			state_machine.transition(&"MoveState")
		elif get_jump():
			state_machine.transition(&"JumpState")
