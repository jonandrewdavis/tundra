@tool
# Move
extends MovementState


func tick(delta, _tick, _is_fresh):
	rotate_player_model(delta)
	move_player(delta)

	force_update_is_on_floor()
	if parent.is_on_floor():
		if get_jump():
			state_machine.transition(&"Jump")
		elif get_main_menu_input():
			state_machine.transition(&"Static")
		elif get_movement_input() == Vector2.ZERO:
			state_machine.transition(&"Idle")
	else:
		state_machine.transition(&"Fall")
