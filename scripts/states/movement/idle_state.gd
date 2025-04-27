@tool
# Idle
extends MovementState

func tick(delta, _tick, _is_fresh):
	rotate_player_model(delta)
	stop_player(delta)
	check_for_ragdoll()

	var input_dir : Vector2 = get_movement_input()
	if input_dir != Vector2.ZERO:
		state_machine.transition(&"Move")

	force_update_is_on_floor()
	if parent.is_on_floor():
		if get_movement_input() == Vector2.ZERO:
			state_machine.transition(&"Idle")
		elif get_jump():
			state_machine.transition(&"Jump")
	else:
		state_machine.transition(&"Fall")
