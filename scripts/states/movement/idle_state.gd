# IdleState
extends MovementState

func tick(delta, _tick, _is_fresh):
	# SLOW DOWN via Friction (disabled while troubleshooting platforms)
	#parent.velocity = parent.velocity.move_toward(Vector3.ZERO, 10000 * delta)
	move_player(delta)
	rotate_player_model(delta)


	if parent.is_on_floor():
		if get_movement_input() != Vector2.ZERO:
			state_machine.transition(&"MoveState")
		elif get_jump():
			state_machine.transition(&"JumpState")
	else:
		state_machine.transition(&"FallState")
