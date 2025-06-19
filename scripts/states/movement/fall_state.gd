@tool
# Fall
extends MovementState

# TODO: on display exit: landing animation!
 
func tick(delta, _tick, _is_fresh):
	rotate_player_model(delta)
	move_player(delta)


	if get_main_menu_input():
		state_machine.transition(&"Static")

	if parent.is_on_floor():
		if get_movement_input() == Vector2.ZERO:
			state_machine.transition(&"Idle")
		elif get_movement_input() != Vector2.ZERO:
			state_machine.transition(&"Move")
		elif get_jump():
			state_machine.transition(&"Jump")
		elif get_main_menu_input():
			state_machine.transition(&"Static")
